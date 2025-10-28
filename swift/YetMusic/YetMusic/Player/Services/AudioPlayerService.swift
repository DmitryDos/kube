import AVKit
import Combine

class AudioPlayerService: NSObject, ObservableObject {
    static let shared = AudioPlayerService()
    private var pipController = PiPController.shared
    
    @Published var isSeeking = false
    private var wasPlayingBeforeSeek = false
    
    @Published var trackInfo = TrackInfo(
        track: nil,
        isPlaying: false,
        currentTime: 0,
        duration: 0,
        progress: 0
    )
    
    let player = AVPlayer()
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    private let queueService = QueueService.shared
    
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
                self?.playNext()
            }
            .store(in: &cancellables)
    }
    
    func load(track: Track) {
        // Используем playableURL вместо fileURL
        guard let videoURL = track.playableURL else {
            print("Video URL not available for track: \(track.title)")
            return
        }
        
        let playerItem = AVPlayerItem(url: videoURL)
        player.replaceCurrentItem(with: playerItem)
        
        trackInfo.track = track
        trackInfo.currentTime = 0
        trackInfo.progress = 0
        trackInfo.duration = 0
    }
    
    func play() {
        if trackInfo.track == nil {
            if let currentTrack = queueService.getCurrentTrack() {
                load(track: currentTrack)
            } else if let track = queueService.getNextTrack() {
                queueService.playTrack(track)
                return
            }
        }
        
        player.play()
        trackInfo.isPlaying = true
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
        if let nextTrack = queueService.moveToNext() {
            load(track: nextTrack)
            play()
        }
    }
    
    func playPrevious() {
        if let prevTrack = queueService.moveToPrevious() {
            load(track: prevTrack)
            play()
        }
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
