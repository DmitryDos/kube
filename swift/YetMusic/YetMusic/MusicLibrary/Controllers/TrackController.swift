import Foundation
import Combine

class TrackController: ObservableObject {
    static let shared = TrackController()
    
    @Published var tracks: [Track] = []
    @Published var isLoading = false
    @Published var canLoadMore = true
    
    private let repository: TrackRepository
    private let videoService = VideoService.shared
    private var currentPage = 0
    private let pageSize = 20
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.repository = TrackRepository()
        loadFirstPage()
        setupVideoObserver()
        observeAuthState()
    }
    
    private func setupVideoObserver() {
        videoService.$videos
            .receive(on: RunLoop.main)
            .sink { [weak self] remoteVideos in
                guard let self = self else { return }
                
                // Обновляем треки при изменении видео на сервере
                let remoteTracks = remoteVideos.map { remoteVideo in
                    Track(
                        title: remoteVideo.title,
                        artist: remoteVideo.description,
                        duration: 0,
                        remoteVideoId: remoteVideo.id,
                        videoURL: remoteVideo.fileURL
                    )
                }
                
                // Обновляем или добавляем новые треки
                for remoteTrack in remoteTracks {
                    if let index = self.tracks.firstIndex(where: { $0.remoteVideoId == remoteTrack.remoteVideoId }) {
                        // Сохраняем локальные поля при обновлении
                        let existing = self.tracks[index]
                        remoteTrack.isSaved = existing.isSaved
                        remoteTrack.localFilePath = existing.localFilePath
                        self.tracks[index] = remoteTrack
                    } else {
                        self.tracks.append(remoteTrack)
                    }
                }
                
                // Удаляем треки, которых больше нет на сервере
                self.tracks.removeAll { track in
                    if let remoteVideoId = track.remoteVideoId {
                        return !remoteVideos.contains(where: { $0.id == remoteVideoId })
                    }
                    return false // Локальные треки не удаляем
                }
            }
            .store(in: &cancellables)
    }

    private func observeAuthState() {
        AuthService.shared.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] isAuth in
                guard let self = self else { return }
                if isAuth {
                    self.loadFirstPage()
                } else {
                    self.tracks = []
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Pagination
    
    func loadFirstPage() {
        currentPage = 0
        tracks = []
        canLoadMore = true
        loadNextPage()
    }
    
    func loadNextPage() {
        guard !isLoading && canLoadMore else { return }
        
        isLoading = true
        
        // Загружаем локальные треки пагинированно
        let localTracks = repository.getTracks(page: currentPage, pageSize: pageSize)
        
        // Загружаем удаленные видео
        videoService.loadVideos(page: currentPage, pageSize: pageSize) { [weak self] remoteVideos in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Объединяем локальные и удаленные треки
                let newTracks = self.mergeTracks(local: localTracks, remote: remoteVideos)
                self.tracks.append(contentsOf: newTracks)
                
                self.canLoadMore = !newTracks.isEmpty
                self.currentPage += 1
                self.isLoading = false
            }
        }
    }
    
    private func mergeTracks(local: [Track], remote: [Video]) -> [Track] {
        var merged = local
        
        // Добавляем удаленные видео, которых нет в локальных
        for remoteVideo in remote {
            if !merged.contains(where: { $0.remoteVideoId == remoteVideo.id }) {
                let track = Track(
                    title: remoteVideo.title,
                    artist: remoteVideo.description,
                    duration: 0,
                    remoteVideoId: remoteVideo.id,
                    videoURL: remoteVideo.fileURL
                )
                merged.append(track)
            }
        }
        
        return merged
    }
    
    // Загрузка видео на сервер
    func uploadVideo(_ videoData: Data, title: String, artist: String) async throws -> Track {
        let video = try await videoService.uploadVideo(
            videoData: videoData,
            title: title,
            description: artist // используем artist как description
        )
        
        let track = Track(
            title: video.title,
            artist: artist,
            duration: 0, // TODO: получать длительность из метаданных
            remoteVideoId: video.id,
            videoURL: video.fileURL
        )
        
        await MainActor.run {
            tracks.append(track)
            repository.saveTrack(track)
            objectWillChange.send()
        }
        
        return track
    }
    
    func deleteTrack(_ track: Track) throws {
        if track.isRemoteVideo, let videoID = track.remoteVideoId {
            Task {
                do { try await VideoService.shared.deleteVideo(videoID: videoID) } catch { print("Failed to delete remote video: \(error)") }
            }
        }

        repository.deleteTrack(track)
        tracks.removeAll { $0.id == track.id }
        objectWillChange.send()
    }
    
    func updateTrackMetadata(track: Track, newTitle: String, newArtist: String) {
        if let index = tracks.firstIndex(where: { $0.id == track.id }) {
            tracks[index].title = newTitle
            tracks[index].artist = newArtist
            repository.updateTrackMetadata(track: tracks[index])
            objectWillChange.send()
        }
    }
    
    func searchTracks(query: String) -> [Track] {
        guard !query.isEmpty else { return tracks }
        return tracks.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.artist.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getRandomTrack() -> Track? {
        return tracks.randomElement()
    }
}
