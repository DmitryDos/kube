import Foundation
import SwiftData

class PlaylistService: ObservableObject {
    static let shared = PlaylistService()
    
    static let likedPlaylistID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let yourTracksPlaylistID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    
    @Published var playlists: [Playlist] = []
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    private let searchService = SearchService.shared

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
    }
    
    private func loadPlaylists() {
        let context = modelContext
        
        do {
            let descriptor = FetchDescriptor<Playlist>()
            let fetchedPlaylists = try context.fetch(descriptor)
            
            if fetchedPlaylists.isEmpty {
                createSystemPlaylists()
            } else {
                self.playlists = fetchedPlaylists
                purgeInvalidTrackReferences()
            }
        } catch {
            createSystemPlaylists()
        }
    }
    
    private func createSystemPlaylists() {
        let context = modelContext
        
        let likedPlaylist = Playlist(id: PlaylistService.likedPlaylistID, name: "Понравившееся", isSystem: true)
        let yourTracks = Playlist(id: PlaylistService.yourTracksPlaylistID, name: "Ваши треки", isSystem: true)
        
        context.insert(likedPlaylist)
        context.insert(yourTracks)
        
        if saveContext() {
            playlists = [likedPlaylist, yourTracks]
        } else {
            createSystemPlaylistsInMemory()
        }
    }
    
    private func createSystemPlaylistsInMemory() {
        let likedPlaylist = Playlist(id: PlaylistService.likedPlaylistID, name: "Понравившееся", isSystem: true)
        let yourTracks = Playlist(id: PlaylistService.yourTracksPlaylistID, name: "Ваши треки", isSystem: true)

        playlists = [likedPlaylist, yourTracks]
    }
    
    func getPlaylistOrder() -> [Playlist] {
        return playlists
    }
    
    func getPlaylist(by id: UUID) -> Playlist? {
        return playlists.first { $0.id == id }
    }
    
    func getTrackIdsForPlaylist(_ playlistID: UUID) -> [UUID] {
        guard let playlist = getPlaylist(by: playlistID) else { return [] }
        return playlist.tracks.map { $0.id }
    }
    
    func getTracksForPlaylist(_ playlistID: UUID) -> [Track] {
        guard let playlist = getPlaylist(by: playlistID) else { return [] }
        
        if playlistID == PlaylistService.yourTracksPlaylistID {
            return getYourTracks()
        }
        
        if let pagination = playlistPagination[playlistID] {
            return pagination.loadedTracks
        }
        
        loadPlaylistTracks(playlistID: playlistID, page: 0)
        return []
    }
    
    func searchTracks(query: String?, completion: @escaping ([Track]) -> Void) {
        var currentPage = 1
        var allTracks: [Track] = []
        
        func loadPage() {
            searchService.searchWithPagination(
                query: query,
                filter: .videos,
                page: currentPage,
                pageSize: 20,
                userId: nil,
                mine: false,
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
        var currentPage = 1
        
        func loadPage() {
            searchService.searchWithPagination(
                query: nil,
                filter: .videos,
                page: currentPage,
                pageSize: 20,
                userId: nil,
                mine: false,
                trackIds: nil
            ) { page, tracks, hasMore in
                let filtered = tracks.filter { selectedTrackIds.contains($0.id) }
                allTracks.append(contentsOf: filtered)
                if hasMore {
                    currentPage += 1
                    loadPage()
                } else {
                    return
                }
            }
        }
        
        loadPage()
        return allTracks
    }
    
    func getAvailableTracksForPlaylist(playlistID: UUID, selectedTrackIds: Set<UUID>, currentTracks: [Track]) -> [Track] {
        var allTracks: [Track] = []
        var currentPage = 1
        
        func loadPage() {
            searchService.searchWithPagination(
                query: nil,
                filter: .videos,
                page: currentPage,
                pageSize: 20,
                userId: nil,
                mine: false,
                trackIds: nil
            ) { page, tracks, hasMore in
                allTracks.append(contentsOf: tracks)
                if hasMore {
                    currentPage += 1
                    loadPage()
                } else {
                    return
                }
            }
        }
        
        loadPage()
        let currentTrackIds = Set(currentTracks.map { $0.id })
        return allTracks.filter { selectedTrackIds.contains($0.id) && !currentTrackIds.contains($0) }
    }
    
    func loadPlaylistTracks(playlistID: UUID, page: Int = 0, completion: (() -> Void)? = nil) {
        if playlistID == PlaylistService.yourTracksPlaylistID {
            loadYourTracks(page: page, completion: completion)
            return
        }
        
        guard let playlist = getPlaylist(by: playlistID) else {
            completion?()
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
        
        searchService.searchWithPagination(
            query: nil,
            filter: .videos,
            page: 1,
            pageSize: 1000,
            userId: nil,
            mine: false,
            trackIds: pageTrackIds
        ) { [weak self] loadedPage, loadedTracks, _ in
            guard let self = self else {
                completion?()
                return
            }
            
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
    
    func loadMoreTracksForPlaylist(playlistID: UUID, completion: (() -> Void)? = nil) {
        guard let pagination = playlistPagination[playlistID],
              pagination.hasMore,
              !pagination.isLoading else {
            completion?()
            return
        }
        
        loadPlaylistTracks(playlistID: playlistID, page: pagination.currentPage + 1, completion: completion)
    }
    
    private func getYourTracks() -> [Track] {
        if let pagination = playlistPagination[PlaylistService.yourTracksPlaylistID] {
            return pagination.loadedTracks
        }
        
        loadYourTracks(page: 0)
        return []
    }
    
    func loadYourTracks(page: Int = 0, completion: (() -> Void)? = nil) {
        if playlistPagination[PlaylistService.yourTracksPlaylistID] == nil {
            playlistPagination[PlaylistService.yourTracksPlaylistID] = PlaylistPaginationState()
        }
        
        guard var pagination = playlistPagination[PlaylistService.yourTracksPlaylistID],
              !pagination.isLoading else {
            completion?()
            return
        }
        
        pagination.isLoading = true
        pagination.currentPage = page
        playlistPagination[PlaylistService.yourTracksPlaylistID] = pagination
        
        searchService.searchWithPagination(
            query: nil,
            filter: .videos,
            page: page + 1,
            pageSize: pagination.pageSize,
            userId: nil,
            mine: true,
            trackIds: nil
        ) { [weak self] loadedPage, tracks, hasMore in
            guard let self = self else {
                completion?()
                return
            }
            
            DispatchQueue.main.async {
                guard var updatedPagination = self.playlistPagination[PlaylistService.yourTracksPlaylistID] else {
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
                self.playlistPagination[PlaylistService.yourTracksPlaylistID] = updatedPagination
                
                completion?()
            }
        }
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
