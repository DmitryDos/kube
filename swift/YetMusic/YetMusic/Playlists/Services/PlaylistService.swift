import Foundation
import SwiftData

class PlaylistService: ObservableObject {
    static let shared = PlaylistService()
    
    static let likedPlaylistID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let videosPlaylistID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static let musicPlaylistID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    static let photosPlaylistID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
    
    @Published var playlists: [Playlist] = []
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    private let searchService = SearchService.shared
    private let authService = AuthService.shared

    private var playlistPagination: [UUID: PlaylistPaginationState] = [:]
    
    struct PlaylistPaginationState {
        var loadedTracks: [Track] = []
        var currentPage: Int = 0
        var pageSize: Int = 20
        var isLoading: Bool = false
        var hasMore: Bool = true
    }
    
    private init() {
        modelContainer = PersistenceController.shared.container
        modelContext = PersistenceController.shared.context
        loadPlaylists()
        preloadSystemPlaylists()
    }
    
    private func preloadSystemPlaylists() {
        print("[PlaylistService] preloadSystemPlaylists: isAuthenticated=\(authService.isAuthenticated), currentUser=\(authService.currentUser?.id.uuidString ?? "nil")")
        loadPlaylistTracks(playlistID: PlaylistService.videosPlaylistID, page: 0)
        loadPlaylistTracks(playlistID: PlaylistService.musicPlaylistID, page: 0)
        loadPlaylistTracks(playlistID: PlaylistService.photosPlaylistID, page: 0)
        loadPlaylistTracks(playlistID: PlaylistService.likedPlaylistID, page: 0)
    }
    
    private func loadPlaylists() {
        let context = modelContext
        
        do {
            let descriptor = FetchDescriptor<Playlist>()
            let fetchedPlaylists = try context.fetch(descriptor)
            self.playlists = fetchedPlaylists.filter { !$0.isSystem }
            purgeInvalidTrackReferences()
        } catch {
            self.playlists = []
        }
    }
    
    func getPlaylistOrder() -> [Playlist] {
        let systemPlaylists = [
            Playlist(id: PlaylistService.videosPlaylistID, name: "Видео", isSystem: true),
            Playlist(id: PlaylistService.musicPlaylistID, name: "Аудио", isSystem: true),
            Playlist(id: PlaylistService.photosPlaylistID, name: "Изображения", isSystem: true),
            Playlist(id: PlaylistService.likedPlaylistID, name: "Понравившееся", isSystem: true)
        ]
        return systemPlaylists + playlists
    }
    
    func getPlaylist(by id: UUID) -> Playlist? {
        if id == PlaylistService.videosPlaylistID {
            return Playlist(id: id, name: "Видео", isSystem: true)
        } else if id == PlaylistService.musicPlaylistID {
            return Playlist(id: id, name: "Аудио", isSystem: true)
        } else if id == PlaylistService.photosPlaylistID {
            return Playlist(id: id, name: "Изображения", isSystem: true)
        } else if id == PlaylistService.likedPlaylistID {
            return Playlist(id: id, name: "Понравившееся", isSystem: true)
        }
        return playlists.first { $0.id == id }
    }
    
    func getTrackIdsForPlaylist(_ playlistID: UUID) -> [UUID] {
        guard let playlist = getPlaylist(by: playlistID) else { return [] }
        return playlist.tracks.map { $0.id }
    }
    
    func getTracksForPlaylist(_ playlistID: UUID) -> [Track] {
        guard let playlist = getPlaylist(by: playlistID) else { return [] }
        
        if playlist.isSystem {
            if let pagination = playlistPagination[playlistID] {
                return pagination.loadedTracks
            }
            loadPlaylistTracks(playlistID: playlistID, page: 0)
            return []
        }
        
        if let pagination = playlistPagination[playlistID] {
            return pagination.loadedTracks
        }
        
        loadPlaylistTracks(playlistID: playlistID, page: 0)
        return []
    }
    
    func searchTracks(query: String?, completion: @escaping ([Track]) -> Void) {
        var allTracks: [Track] = []
        let group = DispatchGroup()
        
        group.enter()
        loadTracksForFilter(query: query, filter: .videos) { tracks in
            allTracks.append(contentsOf: tracks)
            group.leave()
        }
        
        group.enter()
        loadTracksForFilter(query: query, filter: .music) { tracks in
            allTracks.append(contentsOf: tracks)
            group.leave()
        }
        
        group.enter()
        loadTracksForFilter(query: query, filter: .photos) { tracks in
            allTracks.append(contentsOf: tracks)
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(allTracks)
        }
    }
    
    private func loadTracksForFilter(query: String?, filter: SearchFilter, completion: @escaping ([Track]) -> Void) {
        var currentPage = 1
        var allTracks: [Track] = []
        
        func loadPage() {
            searchService.searchWithPagination(
                query: query,
                filter: filter,
                page: currentPage,
                pageSize: 20,
                userId: nil,
                trackIds: nil
            ) { page, tracks, hasMore in
                allTracks.append(contentsOf: tracks)
                if hasMore {
                    currentPage += 1
                    loadPage()
                } else {
                    completion(allTracks)
                }
            }
        }
        
        loadPage()
    }
    
    func getTracksForEditing(selectedTrackIds: Set<UUID>) -> [Track] {
        var allTracks: [Track] = []
        let group = DispatchGroup()
        
        for filter in [SearchFilter.videos, .music, .photos] {
            group.enter()
            loadTracksForFilter(query: nil, filter: filter) { tracks in
                let filtered = tracks.filter { selectedTrackIds.contains($0.id) }
                allTracks.append(contentsOf: filtered)
                group.leave()
            }
        }
        
        group.wait()
        return allTracks
    }
    
    func getAvailableTracksForPlaylist(playlistID: UUID, selectedTrackIds: Set<UUID>, currentTracks: [Track]) -> [Track] {
        var allTracks: [Track] = []
        let group = DispatchGroup()
        
        for filter in [SearchFilter.videos, .music, .photos] {
            group.enter()
            loadTracksForFilter(query: nil, filter: filter) { tracks in
                allTracks.append(contentsOf: tracks)
                group.leave()
            }
        }
        
        group.wait()
        let currentTrackIds = Set(currentTracks.map { $0.id })
        return allTracks.filter { selectedTrackIds.contains($0.id) && !currentTrackIds.contains($0.id) }
    }
    
    func loadPlaylistTracks(playlistID: UUID, page: Int = 0, completion: (() -> Void)? = nil) {
        guard let playlist = getPlaylist(by: playlistID) else {
            print("[PlaylistService] loadPlaylistTracks: плейлист не найден для ID=\(playlistID)")
            completion?()
            return
        }
        
        if playlist.isSystem {
            loadSystemPlaylistTracks(playlistID: playlistID, page: page, completion: completion)
            return
        }
        
        if playlistPagination[playlistID] == nil {
            playlistPagination[playlistID] = PlaylistPaginationState()
        }
        
        guard var pagination = playlistPagination[playlistID],
              !pagination.isLoading else {
            completion?()
            return
        }
        
        pagination.isLoading = true
        pagination.currentPage = page
        playlistPagination[playlistID] = pagination
        
        let allTrackIds = playlist.tracks.map { $0.id }
        let startIndex = page * pagination.pageSize
        let endIndex = min(startIndex + pagination.pageSize, allTrackIds.count)
        
        guard startIndex < allTrackIds.count else {
            DispatchQueue.main.async {
                guard var updatedPagination = self.playlistPagination[playlistID] else {
                    completion?()
                    return
                }
                updatedPagination.isLoading = false
                updatedPagination.hasMore = false
                self.playlistPagination[playlistID] = updatedPagination
                completion?()
            }
            return
        }
        
        let pageTrackIds = Array(allTrackIds[startIndex..<endIndex])
        
        var allLoadedTracks: [Track] = []
        let group = DispatchGroup()
        
        for filter in [SearchFilter.videos, .music, .photos] {
            group.enter()
            searchService.searchWithPagination(
                query: nil,
                filter: filter,
                page: 1,
                pageSize: 1000,
                userId: nil,
                trackIds: pageTrackIds
            ) { loadedPage, tracks, _ in
                allLoadedTracks.append(contentsOf: tracks)
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else {
                completion?()
                return
            }
            
            var uniqueTracks: [Track] = []
            var seenIds = Set<UUID>()
            for track in allLoadedTracks {
                if !seenIds.contains(track.id) {
                    uniqueTracks.append(track)
                    seenIds.insert(track.id)
                }
            }
            
            let loadedTracks = uniqueTracks
            
            DispatchQueue.main.async {
                guard var updatedPagination = self.playlistPagination[playlistID] else {
                    completion?()
                    return
                }
                
                if page == 0 {
                    updatedPagination.loadedTracks = loadedTracks
                } else {
                    let existingIds = Set(updatedPagination.loadedTracks.map { $0.id })
                    let newTracks = loadedTracks.filter { !existingIds.contains($0.id) }
                    updatedPagination.loadedTracks.append(contentsOf: newTracks)
                }
                
                updatedPagination.isLoading = false
                updatedPagination.hasMore = endIndex < allTrackIds.count
                self.playlistPagination[playlistID] = updatedPagination
                
                completion?()
            }
        }
    }
    
    private func loadSystemPlaylistTracks(playlistID: UUID, page: Int = 0, completion: (() -> Void)? = nil) {
        if playlistPagination[playlistID] == nil {
            playlistPagination[playlistID] = PlaylistPaginationState()
        }
        
        guard var pagination = playlistPagination[playlistID],
              !pagination.isLoading else {
            completion?()
            return
        }
        
        pagination.isLoading = true
        pagination.currentPage = page
        playlistPagination[playlistID] = pagination
        
        let filter: SearchFilter
        if playlistID == PlaylistService.videosPlaylistID {
            filter = .videos
        } else if playlistID == PlaylistService.musicPlaylistID {
            filter = .music
        } else if playlistID == PlaylistService.photosPlaylistID {
            filter = .photos
        } else {
            filter = .all
        }
        
        var allTracks: [Track] = []
        let group = DispatchGroup()
        var hasMoreAny = false
        
        let currentUserId = authService.currentUser?.id
        print("[PlaylistService] loadSystemPlaylistTracks: currentUserId=\(currentUserId?.uuidString ?? "nil")")
        
        if filter == .all {
            for f in [SearchFilter.videos, .music, .photos] {
                group.enter()
                searchService.searchWithPagination(
                    query: nil,
                    filter: f,
                    page: page + 1,
                    pageSize: pagination.pageSize,
                    userId: currentUserId,
                    trackIds: nil
                ) { loadedPage, tracks, hasMore in
                    print("[PlaylistService] loadSystemPlaylistTracks: загружено \(tracks.count) треков для фильтра \(f.rawValue)")
                    allTracks.append(contentsOf: tracks)
                    if hasMore {
                        hasMoreAny = true
                    }
                    group.leave()
                }
            }
        } else {
            group.enter()
            searchService.searchWithPagination(
                query: nil,
                filter: filter,
                page: page + 1,
                pageSize: pagination.pageSize,
                userId: currentUserId,
                trackIds: nil
            ) { loadedPage, tracks, hasMore in
                print("[PlaylistService] loadSystemPlaylistTracks: загружено \(tracks.count) треков для фильтра \(filter.rawValue)")
                for track in tracks {
                    print("[PlaylistService] Трек ID: \(track.id), title: \(track.title), videoURL: \(track.videoURL ?? "nil"), duration: \(track.duration)")
                }
                allTracks.append(contentsOf: tracks)
                if hasMore {
                    hasMoreAny = true
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else {
                completion?()
                return
            }
            
            let tracks: [Track]
            if filter == .all {
                var uniqueTracks: [Track] = []
                var seenIds = Set<UUID>()
                for track in allTracks {
                    if !seenIds.contains(track.id) {
                        uniqueTracks.append(track)
                        seenIds.insert(track.id)
                    }
                }
                print("[PlaylistService] loadSystemPlaylistTracks: всего загружено \(allTracks.count) треков, после удаления дубликатов: \(uniqueTracks.count)")
                tracks = uniqueTracks
            } else {
                print("[PlaylistService] loadSystemPlaylistTracks: загружено \(allTracks.count) треков для фильтра \(filter.rawValue)")
                tracks = allTracks
            }
            let hasMore = hasMoreAny
            
            DispatchQueue.main.async {
                guard var updatedPagination = self.playlistPagination[playlistID] else {
                    completion?()
                    return
                }
                
                if page == 0 {
                    updatedPagination.loadedTracks = tracks
                } else {
                    let existingIds = Set(updatedPagination.loadedTracks.map { $0.id })
                    let newTracks = tracks.filter { !existingIds.contains($0.id) }
                    updatedPagination.loadedTracks.append(contentsOf: newTracks)
                }
                
                updatedPagination.isLoading = false
                updatedPagination.hasMore = hasMore
                self.playlistPagination[playlistID] = updatedPagination
                
                completion?()
            }
        }
    }
    
    func loadMoreTracksForPlaylist(playlistID: UUID, completion: (() -> Void)? = nil) {
        guard let pagination = playlistPagination[playlistID],
              pagination.hasMore,
              !pagination.isLoading else {
            completion?()
            return
        }
        
        loadPlaylistTracks(playlistID: playlistID, page: pagination.currentPage + 1, completion: completion)
    }
    
    
    func refreshPlaylistTracks(playlistID: UUID, completion: (() -> Void)? = nil) {
        playlistPagination[playlistID] = PlaylistPaginationState()
        loadPlaylistTracks(playlistID: playlistID, page: 0, completion: completion)
    }
    
    func createPlaylist(name: String) {
        let newPlaylist = Playlist(name: name)
        
        modelContext.insert(newPlaylist)
        
        playlists.append(newPlaylist)
        _ = saveContext()
    }
    
    func renamePlaylist(id: UUID, newName: String) {
        guard let playlist = getPlaylist(by: id) else { return }
        playlist.name = newName
        _ = saveContext()
    }
    
    func deletePlaylist(id: UUID) {
        guard let playlist = getPlaylist(by: id),
              !playlist.isSystem else { return }
        
        modelContext.delete(playlist)
        
        playlists.removeAll { $0.id == id }
        _ = saveContext()
    }
    
    func addTrackToPlaylist(track: Track, playlistID: UUID) {
        guard let playlist = getPlaylist(by: playlistID) else { return }
        
        if !playlist.tracks.contains(where: { $0.id == track.id }) {
            playlist.tracks.append(track)
            _ = saveContext()
        }
    }
    
    func removeTrackFromPlaylist(track: Track, playlistID: UUID) {
        guard let playlist = getPlaylist(by: playlistID) else { return }
        playlist.tracks.removeAll { $0.id == track.id }
        _ = saveContext()
    }

    func removeTrackFromAllPlaylists(trackId: UUID) {
        var changed = false
        for i in playlists.indices {
            let before = playlists[i].tracks.count
            playlists[i].tracks.removeAll { $0.id == trackId }
            if playlists[i].tracks.count != before { changed = true }
        }
        if changed { _ = saveContext() }
    }

    private func purgeInvalidTrackReferences() {}
    
    func toggleLike(track: Track) {
        if isTrackLiked(track) {
            removeTrackFromPlaylist(track: track, playlistID: PlaylistService.likedPlaylistID)
        } else {
            addTrackToPlaylist(track: track, playlistID: PlaylistService.likedPlaylistID)
        }
    }
    
    func isTrackLiked(_ track: Track) -> Bool {
        guard let likedPlaylist = getPlaylist(by: PlaylistService.likedPlaylistID) else { return false }
        return likedPlaylist.tracks.contains(where: { $0.id == track.id })
    }

    @discardableResult
    private func saveContext() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            print("❌ Error saving playlists: \(error)")
            return false
        }
    }
}
