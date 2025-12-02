import Foundation
import Combine

class TrackController: ObservableObject {
    static let shared = TrackController()
    
    @Published var tracks: [Track] = []
    @Published var isLoading = false
    @Published var canLoadMore = true
    
    private let repository: TrackRepository
    private let searchService = SearchService.shared
    private var currentPage = 0
    private let pageSize = 20
    private var currentQuery: String? = nil
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.repository = TrackRepository()
        loadFirstPage()
        observeAuthState()
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
        
        searchService.searchWithPagination(
            query: currentQuery,
            filter: .videos,
            page: currentPage + 1,
            pageSize: pageSize,
            userId: nil,
            trackIds: nil
        ) { [weak self] _, remoteVideos, hasMore in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                let newTracks: [Track] = remoteVideos.map { track in
                    if let existing = self.repository.findById(track.id) ?? self.tracks.first(where: { $0.id == track.id }) {
                        track.isSaved = existing.isSaved
                        track.localFilePath = existing.localFilePath
                    }
                    
                    return track
                }
                
                self.tracks.append(contentsOf: newTracks)
                self.canLoadMore = hasMore
                self.currentPage += 1
                self.isLoading = false
            }
        }
    }

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

            // Прямое создание Track из RemoteVideo
            let track = Track(
                id: video.id,
                title: title.isEmpty ? video.title : title,
                desc: artist.isEmpty ? video.desc : artist,
                duration: 0,
                videoURL: video.videoURL,
                thumbnailURL: video.thumbnailURL,
                ownerUserId: video.ownerUserId,
                dateAdded: video.dateAdded
            )
            track.fileSize = video.fileSize
            track.status = video.status
            
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
        if let ownerId = track.ownerUserId, let currentId = AuthService.shared.currentUser?.id, ownerId == currentId,
           !track.isSaved {
            Task {
                do {
                    try await VideoService.shared.deleteVideo(videoID: track.id)
                } catch {
                    print("Failed to delete remote video: \(error)")
                }
            }
        }

        repository.deleteTrack(track)
        tracks.removeAll { $0.id == track.id }
        objectWillChange.send()

        PlaylistService.shared.removeTrackFromAllPlaylists(trackId: track.id)
    }
    
    func updateTrackMetadata(track: Track, newTitle: String, newDescription: String) {
        if let index = tracks.firstIndex(where: { $0.id == track.id }) {
            tracks[index].title = newTitle
            tracks[index].desc = newDescription
            repository.updateTrackMetadata(track: tracks[index])
            objectWillChange.send()
        }
    }
    
    func searchTracks(query: String) -> [Track] {
        guard !query.isEmpty else { return tracks }
        return tracks.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.desc.localizedCaseInsensitiveContains(query) // Используем desc для поиска по artist
        }
    }
    
    func getRandomTrack() -> Track? {
        return tracks.randomElement()
    }
}
