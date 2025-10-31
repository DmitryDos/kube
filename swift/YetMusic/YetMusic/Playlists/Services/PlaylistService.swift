import Foundation
import SwiftData

class PlaylistService: ObservableObject {
    static let shared = PlaylistService()
    
    static let likedPlaylistID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let allMusicPlaylistID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    
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
        
        context.insert(likedPlaylist)
        context.insert(allMusicPlaylist)
        
        if saveContext() {
            playlists = [likedPlaylist, allMusicPlaylist]
            print("✅ Created system playlists in SwiftData")
        } else {
            createSystemPlaylistsInMemory()
        }
    }
    
    private func createSystemPlaylistsInMemory() {
        let likedPlaylist = Playlist(id: PlaylistService.likedPlaylistID, name: "Понравившееся", isSystem: true)
        let allMusicPlaylist = Playlist(id: PlaylistService.allMusicPlaylistID, name: "Вся музыка", isSystem: true)
        
        playlists = [likedPlaylist, allMusicPlaylist]
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
        } else {
            return playlist.tracks
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
