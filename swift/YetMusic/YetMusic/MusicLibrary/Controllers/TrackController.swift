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
    private var currentQuery: String? = nil
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
                        videoURL: remoteVideo.fileURL,
                        thumbnailURL: remoteVideo.thumbnailURL,
                        ownerUserId: remoteVideo.userId
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
    
    func loadFirstPage(query: String? = nil) {
        currentPage = 0
        tracks = []
        canLoadMore = true
        currentQuery = query
        loadNextPage()
    }
    
    func loadNextPage() {
        guard !isLoading && canLoadMore else { return }
        
        isLoading = true
        
        // Загружаем удаленные видео (глобальные) с серверной пагинацией и фильтром
        videoService.loadVideos(page: currentPage, pageSize: pageSize, query: currentQuery) { [weak self] remoteVideos in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Маппим видео в треки, подтягиваем локальные флаги при наличии
                let newTracks: [Track] = remoteVideos.compactMap { remoteVideo in
                    let existing = self.repository.findByRemoteVideoId(remoteVideo.id) ?? self.tracks.first(where: { $0.remoteVideoId == remoteVideo.id })
                    let t = Track(
                        title: remoteVideo.title,
                        artist: remoteVideo.description,
                        duration: 0,
                        remoteVideoId: remoteVideo.id,
                        videoURL: remoteVideo.fileURL,
                        thumbnailURL: remoteVideo.thumbnailURL,
                        ownerUserId: remoteVideo.userId
                    )
                    if let existing = existing {
                        t.isSaved = existing.isSaved
                        t.localFilePath = existing.localFilePath
                    }
                    return t
                }
                self.tracks.append(contentsOf: newTracks)
                
                self.canLoadMore = !newTracks.isEmpty
                self.currentPage += 1
                self.isLoading = false
            }
        }
    }

    // Серверный поиск по "Вся музыка"
    func searchAllMusic(query: String) {
        loadFirstPage(query: query)
    }
    
    func uploadVideo(_ videoData: Data, title: String, artist: String) async throws -> Track {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        
        do {
            try videoData.write(to: tempURL)
            defer {
                try? FileManager.default.removeItem(at: tempURL)
            }
            
            let video = try await UploadService.shared.uploadVideo(fileURL: tempURL)
            
            if !title.isEmpty || !artist.isEmpty {
                try await VideoService.shared.updateVideoMetadata(
                    videoID: video.id,
                    title: title.isEmpty ? nil : title,
                    description: artist.isEmpty ? nil : artist,
                    thumbnail: nil
                )
            }
            
            let track = Track(
                title: title.isEmpty ? video.title : title,
                artist: artist.isEmpty ? video.description : artist,
                duration: 0,
                remoteVideoId: video.id,
                videoURL: video.fileURL,
                thumbnailURL: video.thumbnailURL,
                ownerUserId: video.userId
            )
            
            await MainActor.run {
                tracks.append(track)
                repository.saveTrack(track)
                objectWillChange.send()
            }
            
            return track
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            throw error
        }
    }
    
    func deleteTrack(_ track: Track) throws {
        // Только автор может удалять
        if let ownerId = track.ownerUserId, let currentId = AuthService.shared.currentUser?.id, ownerId == currentId,
           track.isRemoteVideo, let videoID = track.remoteVideoId {
            Task {
                do { try await VideoService.shared.deleteVideo(videoID: videoID) } catch { print("Failed to delete remote video: \(error)") }
            }
        } else {
            // Нельзя удалять чужие треки с сервера
        }

        repository.deleteTrack(track)
        tracks.removeAll { $0.id == track.id }
        objectWillChange.send()

        // Purge from playlists to avoid stale SwiftData references
        PlaylistService.shared.removeTrackFromAllPlaylists(trackId: track.id)
    }
    
    func updateTrackMetadata(track: Track, newTitle: String, newArtist: String) {
        if let index = tracks.firstIndex(where: { $0.id == track.id }) {
            tracks[index].title = newTitle
            tracks[index].artist = newArtist
            repository.updateTrackMetadata(track: tracks[index])
            objectWillChange.send()
        }
    }
    
    // Локальный поиск оставим как быстрый фильтр по уже загруженным результатам
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
