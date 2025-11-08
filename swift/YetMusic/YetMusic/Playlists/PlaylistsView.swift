import SwiftUI

struct PlaylistsView: View {
    @StateObject private var playlistService = PlaylistService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Environment(\.isLandscape) private var isLandscape
    @State private var searchText: String = ""
    @State private var pendingSearch: DispatchWorkItem?

    @State private var editingPlaylistID: UUID? = nil
    @State private var selectedTracks: Set<UUID> = []
    @State private var tempPlaylistName: String = ""
    @State private var editingPlaylistTracks: [Track] = []

    private func updateEditingPlaylistTracks() {
        guard editingPlaylistID != nil else {
            editingPlaylistTracks = []
            return
        }
        editingPlaylistTracks = playlistService.getTracksForEditing(selectedTrackIds: selectedTracks)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                searchBar
                scrollContent
            }
        }
    }

    private var filteredPlaylists: [Playlist] {
        let allPlaylists = playlistService.getPlaylistOrder()
        
        if searchText.isEmpty {
            return allPlaylists
        }
        
        let searchLowercased = searchText.lowercased()
        
        return allPlaylists.filter { playlist in
            if playlist.id == PlaylistService.likedPlaylistID {
                return true
            }

            if playlist.id == editingPlaylistID {
                return true
            }

            return playlist.name.lowercased().contains(searchLowercased)
        }
    }

    private func getTracksForPlaylist(_ playlist: Playlist) -> [Track] {
        if playlist.id == editingPlaylistID {
            return editingPlaylistTracks
        }
        
        var tracks = playlistService.getTracksForPlaylist(playlist.id)
        
        if !searchText.isEmpty {
            let searchLowercased = searchText.lowercased()
            tracks = tracks.filter { track in
                track.title.lowercased().contains(searchLowercased) ||
                track.desc.lowercased().contains(searchLowercased)
            }
        }
        
        return tracks
    }
    
    private func shouldShowPlaylist(_ playlist: Playlist, tracks: [Track], isEditingThisPlaylist: Bool) -> Bool {
        if isEditingThisPlaylist ||
           isSystemPlaylist(playlist.id) ||
           !tracks.isEmpty ||
           playlistMatchesSearch(playlist) {
            return true
        }

        return searchText.isEmpty
    }

    private func playlistMatchesSearch(_ playlist: Playlist) -> Bool {
        guard !searchText.isEmpty else { return false }
        
        let searchLowercased = searchText.lowercased()
        return playlist.name.lowercased().contains(searchLowercased)
    }

    private var searchBar: some View {
        HStack {
            ExpandableSearchBar(
                text: $searchText,
                placeholder: "Поиск треков и плейлистов",
                onSubmit: {
                    triggerServerSearchNow()
                },
                onClear: {
                    playlistService.searchTracks(query: nil) { _ in }
                }
            )
            
            Spacer()
                .frame(width: isLandscape ? 0 : 54)
        }
        .onChange(of: searchText) { _ in scheduleDebouncedServerSearch() }
    }

    private func scheduleDebouncedServerSearch() {
        pendingSearch?.cancel()
        let work = DispatchWorkItem { triggerServerSearchNow() }
        pendingSearch = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    private func triggerServerSearchNow() {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        playlistService.searchTracks(query: q.isEmpty ? nil : q) { _ in
            updateEditingPlaylistTracks()
        }
    }

    private var scrollContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if editingPlaylistID == nil {
                    addPlaylistButton
                }
                
                ForEach(filteredPlaylists) { playlist in
                    playlistSection(for: playlist)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private var addPlaylistButton: some View {
        Button {
            startPlaylistCreation()
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(themeObserver.themedAccentColor)
                
                Text("Добавить плейлист")
                    .font(.headline)
                    .foregroundColor(themeObserver.themedPrimaryColor)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeObserver.contrastColor)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .contentShape(Rectangle())
    }

    private func playlistSection(for playlist: Playlist) -> some View {
        let tracks = getTracksForPlaylist(playlist)
        let isEditingThisPlaylist = editingPlaylistID == playlist.id
        let isEditingPlaylist = editingPlaylistID != nil
        
        return Group {
            if shouldShowPlaylist(playlist, tracks: tracks, isEditingThisPlaylist: isEditingThisPlaylist) {
                PlaylistSectionView(
                    title: isEditingThisPlaylist ? tempPlaylistName : playlist.name,
                    tracks: tracks,
                    isSystem: isSystemPlaylist(playlist.id),
                    isEditingMode: isEditingThisPlaylist,
                    showSelectionToggles: isEditingPlaylist,
                    selectedTracks: $selectedTracks,
                    tempPlaylistName: $tempPlaylistName,
                    onSavePlaylist: {
                        if isEditingThisPlaylist {
                            savePlaylist()
                        }
                    },
                    onDeletePlaylist: {
                        if isEditingThisPlaylist {
                            deletePlaylist(playlist.id)
                        }
                    },
                    onTrackLongPress: { track in
                        showTrackInfoModal(for: track)
                    },
                    onPlaylistLongPress: {
                        if !isSystemPlaylist(playlist.id) && !isEditingPlaylist && playlist.id != PlaylistService.yourTracksPlaylistID {
                            startPlaylistEditing(playlist.id)
                        }
                    }
                )
            }
        }
    }
    
    private func startPlaylistCreation() {
        playlistService.createPlaylist(name: "Новый плейлист")
        if let newPlaylist = playlistService.getPlaylistOrder()
            .first(where: { !isSystemPlaylist($0.id) && $0.name == "Новый плейлист" }) {
            editingPlaylistID = newPlaylist.id
            tempPlaylistName = "Новый плейлист"
        }
        selectedTracks.removeAll()
    }
    
    private func startPlaylistEditing(_ playlistID: UUID) {
        editingPlaylistID = playlistID
        if let playlist = playlistService.getPlaylist(by: playlistID) {
            tempPlaylistName = playlist.name
            let currentTracks = playlistService.getTracksForPlaylist(playlistID)
            selectedTracks = Set(currentTracks.map { $0.id })
            updateEditingPlaylistTracks()
        }
    }
    
    private func savePlaylist() {
        guard let playlistID = editingPlaylistID,
              let playlist = playlistService.getPlaylist(by: playlistID) else { return }
        
        let newName = tempPlaylistName.trimmingCharacters(in: .whitespaces)
        guard !newName.isEmpty else { return }
        
        if playlist.name != newName {
            playlistService.renamePlaylist(id: playlistID, newName: newName)
        }
        
        let currentTracks = playlistService.getTracksForPlaylist(playlistID)
        let currentTrackIds = Set(currentTracks.map { $0.id })
        
        if currentTrackIds != selectedTracks {
            for track in currentTracks {
                if !selectedTracks.contains(track.id) {
                    playlistService.removeTrackFromPlaylist(track: track, playlistID: playlistID)
                }
            }
            
            let tracksToAdd = playlistService.getAvailableTracksForPlaylist(
                playlistID: playlistID,
                selectedTrackIds: selectedTracks,
                currentTracks: currentTracks
            )
            
            for track in tracksToAdd {
                playlistService.addTrackToPlaylist(track: track, playlistID: playlistID)
            }
        }
        
        DispatchQueue.main.async {
            self.editingPlaylistID = nil
            self.selectedTracks.removeAll()
            self.tempPlaylistName = ""
        }
    }
        
    private func showTrackInfoModal(for track: Track) {
        ModalProvider.shared.show(ShowTrackInfoModal(track: track))
    }
    
    private func deletePlaylist(_ playlistID: UUID) {
        playlistService.deletePlaylist(id: playlistID)
        DispatchQueue.main.async {
            self.editingPlaylistID = nil
            self.selectedTracks.removeAll()
            self.tempPlaylistName = ""
        }
    }
    
    private func isSystemPlaylist(_ id: UUID) -> Bool {
        return id == PlaylistService.likedPlaylistID || id == PlaylistService.yourTracksPlaylistID
    }
}

#Preview {
    PlaylistsView()
}
