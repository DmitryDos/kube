import AVKit
import AVFoundation
import Combine

class AudioPlayerService: NSObject, ObservableObject {
    static let shared = AudioPlayerService()
    private var pipController = PiPController.shared
    
    @Published var isSeeking = false
    private var wasPlayingBeforeSeek = false
    
    @Published var trackInfo = TrackInfo(
        track: nil,
        isPlaying: false,
        isBuffering: false,
        currentTime: 0,
        duration: 0,
        progress: 0,
        bufferedProgress: 0
    )
    
    let player = AVPlayer()
    private var timeObserver: Any?
    private var itemObservers: [NSKeyValueObservation] = []
    private var cancellables = Set<AnyCancellable>()

    private let queueService = QueueService.shared
    @Published var isAutoPlayEnabled: Bool = true
    
    override init() {
        super.init()
        setupAudioSession()
        setupTimeObserver()
        setupPlaybackFinishedHandler()
        
        NotificationCenter.default.publisher(for: .pipDidClose)
            .sink { [weak self] _ in
                self?.play()
            }
            .store(in: &cancellables)
    }
    
    private func setupAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            let currentTime = time.seconds
            let duration = self.player.currentItem?.duration.seconds ?? 0

            let safeCurrentTime = currentTime.isFinite && !currentTime.isNaN ? currentTime : 0
            let safeDuration = duration.isFinite && !duration.isNaN ? duration : 0
            let progress = safeDuration > 0 ? safeCurrentTime / safeDuration : 0
            
            self.trackInfo.currentTime = safeCurrentTime
            self.trackInfo.duration = safeDuration
            self.trackInfo.progress = progress
        }
    }
    
    private func setupPlaybackFinishedHandler() {
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.isAutoPlayEnabled {
                    self.playNext()
                } else {
                    // Stop and clear current
                    self.player.replaceCurrentItem(with: nil)
                    self.trackInfo.track = nil
                    self.trackInfo.isPlaying = false
                    self.queueService.clearCurrentSelectionAfterFinish()
                }
            }
            .store(in: &cancellables)
    }
    
    func load(track: Track) {
        print("[AudioPlayerService] 🎵 Loading track: \(track.title) (ID: \(track.id.uuidString))")
        print("[AudioPlayerService] Track status: \(track.status ?? "nil")")
        print("[AudioPlayerService] Track fileSize: \(track.fileSize ?? 0) bytes")
        
        // Проверяем статус видео перед загрузкой
        if let status = track.status, status != "ready" {
            print("[AudioPlayerService] ⚠️ Video status is '\(status)', not 'ready'. May not play correctly.")
        }
        
        if track.isSaved, let local = track.playableURL {
            print("[AudioPlayerService] 📁 Loading from local file: \(local.path)")
            let item = AVPlayerItem(url: local)
            player.replaceCurrentItem(with: item)
            observeItem(item)
        } else {
            // Используем track.id для стрима, а не track.videoURL (который содержит presigned URL)
            // Для просмотра видео авторизация не требуется
            let base = AppConfig.apiBaseURL
            let streamURLString = base + "/api/videos/\(track.id.uuidString)/stream/proxy"
            print("[AudioPlayerService] 🌐 Loading from stream URL: \(streamURLString)")
            
            guard let url = URL(string: streamURLString) else {
                print("[AudioPlayerService] ❌ Failed to create URL from: \(streamURLString)")
                return
            }

            // Настройка AVURLAsset для стриминга
            // Не добавляем Range заголовок здесь, AVPlayer сам управляет range requests
            let asset = AVURLAsset(url: url, options: nil)
            
            print("[AudioPlayerService] 📦 Created AVURLAsset, loading...")
            let item = AVPlayerItem(asset: asset)
            player.replaceCurrentItem(with: item)
            observeItem(item)

            PreloadService.shared.startPreloading(for: track)
        }
        
        trackInfo.track = track
        trackInfo.currentTime = 0
        trackInfo.progress = 0
        trackInfo.duration = 0
    }

    private func observeItem(_ item: AVPlayerItem) {
        // Clear previous observers
        itemObservers.forEach { $0.invalidate() }
        itemObservers.removeAll()

        // Status observer - критически важно для диагностики
        let statusObs = item.observe(\.status, options: [.new, .initial]) { [weak self] item, change in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    print("[AudioPlayerService] ✅ Item ready to play")
                    if let url = (item.asset as? AVURLAsset)?.url {
                        print("[AudioPlayerService] URL: \(url.absoluteString)")
                    }
                    if let duration = item.asset.duration.seconds as? Double, duration.isFinite {
                        print("[AudioPlayerService] Duration: \(duration) seconds")
                    }
                case .failed:
                    print("[AudioPlayerService] ❌ Item failed to load")
                    if let error = item.error {
                        print("[AudioPlayerService] Error: \(error.localizedDescription)")
                        print("[AudioPlayerService] Error domain: \((error as NSError).domain)")
                        print("[AudioPlayerService] Error code: \((error as NSError).code)")
                        if let userInfo = (error as NSError).userInfo as? [String: Any] {
                            print("[AudioPlayerService] Error userInfo: \(userInfo)")
                        }
                    }
                    if let errorLog = item.errorLog() {
                        print("[AudioPlayerService] Error log entries: \(errorLog.events.count)")
                        for event in errorLog.events {
                            print("[AudioPlayerService] Error log: \(event.errorComment ?? "unknown")")
                        }
                    }
                case .unknown:
                    print("[AudioPlayerService] ⏳ Item status unknown (loading...)")
                @unknown default:
                    print("[AudioPlayerService] ⚠️ Unknown status")
                }
            }
        }

        // Buffering state
        let obs1 = item.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, change in
            DispatchQueue.main.async { 
                self?.trackInfo.isBuffering = item.isPlaybackBufferEmpty
                if item.isPlaybackBufferEmpty {
                    print("[AudioPlayerService] ⏳ Buffer is empty")
                }
            }
        }
        // Likely to keep up
        let obs2 = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, change in
            DispatchQueue.main.async { 
                self?.trackInfo.isBuffering = !item.isPlaybackLikelyToKeepUp
                if item.isPlaybackLikelyToKeepUp {
                    print("[AudioPlayerService] ✅ Playback likely to keep up")
                } else {
                    print("[AudioPlayerService] ⏳ Playback may stall")
                }
            }
        }
        // Loaded time ranges → buffered progress
        let obs3 = item.observe(\.loadedTimeRanges, options: [.new]) { [weak self] item, change in
            guard let self = self else { return }
            let ranges = item.loadedTimeRanges
            guard let timeRange = ranges.first?.timeRangeValue else { return }
            let bufferedEnd = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration)
            let duration = item.duration.seconds
            let safeDuration = duration.isFinite && !duration.isNaN && duration > 0 ? duration : 0
            let buffered = safeDuration > 0 ? min(1.0, bufferedEnd / safeDuration) : 0
            DispatchQueue.main.async { 
                self.trackInfo.bufferedProgress = buffered
                if buffered > 0 {
                    print("[AudioPlayerService] 📊 Buffered: \(Int(buffered * 100))% (\(bufferedEnd)s / \(safeDuration)s)")
                }
            }
        }

        itemObservers = [statusObs, obs1, obs2, obs3]
        
        // Обработка ошибок через NotificationCenter
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemFailedToPlay),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: item
        )
    }
    
    @objc private func playerItemFailedToPlay(_ notification: Notification) {
        print("[AudioPlayerService] ❌ Player item failed to play to end time")
        if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
            print("[AudioPlayerService] Error: \(error.localizedDescription)")
        }
    }
    
    func play() {
        if trackInfo.track == nil {
            if let currentTrack = queueService.getCurrentTrack() {
                load(track: currentTrack)
            } else {
                queueService.playNextTrack()
                return
            }
        }
        
        print("[AudioPlayerService] ▶️ Starting playback")
        print("[AudioPlayerService] Player status: \(player.status.rawValue)")
        if let item = player.currentItem {
            print("[AudioPlayerService] Item status: \(item.status.rawValue)")
            print("[AudioPlayerService] Item canPlay: \(item.status == .readyToPlay)")
        }
        
        player.play()
        trackInfo.isPlaying = true
        
        // Проверяем через небольшую задержку, началось ли воспроизведение
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            if self.player.rate == 0 && self.trackInfo.isPlaying {
                print("[AudioPlayerService] ⚠️ Playback started but player rate is 0")
                if let error = self.player.error {
                    print("[AudioPlayerService] Player error: \(error.localizedDescription)")
                }
                if let item = self.player.currentItem, let error = item.error {
                    print("[AudioPlayerService] Item error: \(error.localizedDescription)")
                }
            } else if self.player.rate > 0 {
                print("[AudioPlayerService] ✅ Playback is active (rate: \(self.player.rate))")
            }
        }
    }
    
    func pause() {
        player.pause()
        trackInfo.isPlaying = false
    }
    
    func startSeeking() {
        wasPlayingBeforeSeek = trackInfo.isPlaying
        if wasPlayingBeforeSeek {
            player.pause()
        }
        isSeeking = true
    }
        
    func endSeeking() {
        isSeeking = false
        if wasPlayingBeforeSeek {
            player.play()
        }
        wasPlayingBeforeSeek = false
    }
        
    func seek(to progress: Double) {
        guard progress.isFinite, trackInfo.duration.isFinite, trackInfo.duration > 0 else { return }
        
        let newTime = progress * trackInfo.duration
        let time = CMTime(seconds: newTime, preferredTimescale: 1000)
        
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] completed in
            if completed {
                DispatchQueue.main.async {
                    self?.trackInfo.progress = progress
                    self?.trackInfo.currentTime = newTime
                }
            }
        }
    }

    func seekForward(seconds: Double) {
        guard trackInfo.duration > 0 else { return }
        let newTime = min(trackInfo.currentTime + seconds, trackInfo.duration)
        let progress = newTime / trackInfo.duration
        seek(to: progress)
    }

    func seekBackward(seconds: Double) {
        guard trackInfo.duration > 0 else { return }
        let newTime = max(trackInfo.currentTime - seconds, 0)
        let progress = newTime / trackInfo.duration
        seek(to: progress)
    }
    
    func playNext() {
        queueService.playNextTrack()
    }
    
    func playPrevious() {
        queueService.playPreviousTrack()
    }
    
    func tryPip() {
        if !pipController.isPiPActive {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.pipController.startPiP()
            }
        }
    }
    
    deinit {
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
    }
}
