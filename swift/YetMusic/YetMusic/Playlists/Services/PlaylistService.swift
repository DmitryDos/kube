import Foundation
import SwiftData

class PlaylistService: ObservableObject {
    static let shared = PlaylistService()
    
    static let likedPlaylistID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let allMusicPlaylistID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static let yourTracksPlaylistID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    
    @Published var playlists: [Playlist] = []
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
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
                print("✅ Loaded \(fetchedPlaylists.count) playlists from SwiftData")
            }
        } catch {
            print("❌ Error loading playlists: \(error)")
            createSystemPlaylists()
        }
    }
    
    private func createSystemPlaylists() {
        let context = modelContext
        
        let likedPlaylist = Playlist(id: PlaylistService.likedPlaylistID, name: "Понравившееся", isSystem: true)
        let allMusicPlaylist = Playlist(id: PlaylistService.allMusicPlaylistID, name: "Вся музыка", isSystem: true)
        let yourTracks = Playlist(id: PlaylistService.yourTracksPlaylistID, name: "Ваши треки", isSystem: true)
        
        context.insert(likedPlaylist)
        context.insert(allMusicPlaylist)
        context.insert(yourTracks)
        
        if saveContext() {
            playlists = [likedPlaylist, allMusicPlaylist, yourTracks]
            print("✅ Created system playlists in SwiftData")
        } else {
            createSystemPlaylistsInMemory()
        }
    }
    
    private func createSystemPlaylistsInMemory() {
        let likedPlaylist = Playlist(id: PlaylistService.likedPlaylistID, name: "Понравившееся", isSystem: true)
        let allMusicPlaylist = Playlist(id: PlaylistService.allMusicPlaylistID, name: "Вся музыка", isSystem: true)
        let yourTracks = Playlist(id: PlaylistService.yourTracksPlaylistID, name: "Ваши треки", isSystem: true)

        playlists = [likedPlaylist, allMusicPlaylist, yourTracks]
        print("✅ Created system playlists in memory")
    }
    
    // MARK: - Public Methods
    
    func getPlaylistOrder() -> [Playlist] {
        return playlists
    }
    
    func getPlaylist(by id: UUID) -> Playlist? {
        return playlists.first { $0.id == id }
    }
    
    func getTracksForPlaylist(_ playlistID: UUID) -> [Track] {
        guard let playlist = getPlaylist(by: playlistID) else { return [] }
        
        if playlistID == PlaylistService.allMusicPlaylistID {
            return TrackController.shared.tracks
        } else if playlistID == PlaylistService.yourTracksPlaylistID {
            let currentUserId = AuthService.shared.currentUser?.id
            return TrackController.shared.tracks.filter { $0.ownerUserId == currentUserId }
        } else {
            let live = TrackController.shared.tracks
            let liveIds = Set(live.map { $0.id })
            return playlist.tracks.filter { liveIds.contains($0.id) }
        }
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

    // MARK: - Cleanup helpers
    func removeTrackFromAllPlaylists(trackId: UUID) {
        var changed = false
        for i in playlists.indices {
            let before = playlists[i].tracks.count
            playlists[i].tracks.removeAll { $0.id == trackId }
            if playlists[i].tracks.count != before { changed = true }
        }
        if changed { _ = saveContext() }
    }

    private func purgeInvalidTrackReferences() {
        let liveIds = Set(TrackController.shared.tracks.map { $0.id })
        var changed = false
        for i in playlists.indices {
            let before = playlists[i].tracks.count
            playlists[i].tracks.removeAll { !liveIds.contains($0.id) }
            if playlists[i].tracks.count != before { changed = true }
        }
        if changed { _ = saveContext() }
    }
    
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
