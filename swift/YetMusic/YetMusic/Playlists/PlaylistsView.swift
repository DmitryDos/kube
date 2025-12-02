import SwiftUI

struct PlaylistChipItem: Hashable, CustomStringConvertible {
    enum ChipType: Hashable {
        case create
        case all
        case videos
        case music
        case photos
        case playlist(UUID)
    }
    
    let type: ChipType
    
    var description: String {
        switch type {
        case .create:
            return "Создать плейлист"
        case .all:
            return "Всё"
        case .videos:
            return "Видео"
        case .music:
            return "Музыка"
        case .photos:
            return "Фото"
        case .playlist(let id):
            return PlaylistService.shared.getPlaylist(by: id)?.name ?? "Плейлист"
        }
    }
    
    var playlistID: UUID? {
        if case .playlist(let id) = type {
            return id
        }
        return nil
    }
}

struct PlaylistsView: View {
    @StateObject private var playlistService = PlaylistService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Environment(\.isLandscape) private var isLandscape
    
    @State private var searchText: String = ""
    @State private var selectedChip: PlaylistChipItem = PlaylistChipItem(type: .all)
    @State private var pendingSearch: DispatchWorkItem?
    @State private var selectedFilters: Set<String> = []
    @State private var sortOrder: FilterSettingsModal.SortOrder = .newest
    @State private var hasActiveFilters: Bool = false

    private var chipItems: [PlaylistChipItem] {
        var items: [PlaylistChipItem] = [
            PlaylistChipItem(type: .create),
            PlaylistChipItem(type: .all),
            PlaylistChipItem(type: .videos),
            PlaylistChipItem(type: .music),
            PlaylistChipItem(type: .photos)
        ]
        
        let allPlaylists = playlistService.getPlaylistOrder()
        for playlist in allPlaylists where !playlist.isSystem {
            items.append(PlaylistChipItem(type: .playlist(playlist.id)))
        }
        
        return items
    }
    
    private var filteredResults: [Track] {
        let allPlaylists = playlistService.getPlaylistOrder()
        var allTracks: [Track] = []
        
        switch selectedChip.type {
        case .create:
            return []
        case .all:
            for playlist in allPlaylists {
                allTracks.append(contentsOf: playlistService.getTracksForPlaylist(playlist.id))
            }
        case .videos:
            if let videosPlaylist = allPlaylists.first(where: { $0.id == PlaylistService.videosPlaylistID }) {
                allTracks = playlistService.getTracksForPlaylist(videosPlaylist.id)
            }
        case .music:
            if let musicPlaylist = allPlaylists.first(where: { $0.id == PlaylistService.musicPlaylistID }) {
                allTracks = playlistService.getTracksForPlaylist(musicPlaylist.id)
            }
        case .photos:
            if let photosPlaylist = allPlaylists.first(where: { $0.id == PlaylistService.photosPlaylistID }) {
                allTracks = playlistService.getTracksForPlaylist(photosPlaylist.id)
            }
        case .playlist(let id):
            allTracks = playlistService.getTracksForPlaylist(id)
        }
        
        if !searchText.isEmpty {
            let searchLowercased = searchText.lowercased()
            allTracks = allTracks.filter { track in
                track.title.lowercased().contains(searchLowercased) ||
                track.desc.lowercased().contains(searchLowercased)
            }
        }
        
        var uniqueTracks: [Track] = []
        var seenIds = Set<UUID>()
        for track in allTracks {
            if !seenIds.contains(track.id) {
                uniqueTracks.append(track)
                seenIds.insert(track.id)
            }
        }
        
        return uniqueTracks
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                searchBar
                
                if hasActiveFilters {
                    Button {
                        selectedFilters.removeAll()
                        sortOrder = .newest
                        hasActiveFilters = false
                    } label: {
                        Text("Сбросить фильтры")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeObserver.themedAccentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(themeObserver.contrastColor)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, isLandscape ? 0 : 12)
                    .padding(.vertical, 8)
                } else {
                    HStack(spacing: 8) {
                        Button {
                            ModalProvider.shared.showModalContainer(
                                FilterSettingsModal(
                                    selectedFilters: $selectedFilters,
                                    sortOrder: $sortOrder,
                                    availableFilters: chipItems.map { $0.description },
                                    onApply: {
                                        hasActiveFilters = !selectedFilters.isEmpty || sortOrder != .newest
                                    },
                                    onReset: {
                                        selectedFilters.removeAll()
                                        sortOrder = .newest
                                        hasActiveFilters = false
                                    }
                                )
                            )
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 20))
                                .foregroundColor(themeObserver.themedAccentColor)
                                .frame(width: 44, height: 44)
                                .background(themeObserver.contrastColor)
                                .cornerRadius(12)
                        }
                
                FilterChipsView(
                    items: chipItems,
                    selectedItem: $selectedChip
                ) { chip in
                    if chip.type == .create {
                        DispatchQueue.main.async {
                            startPlaylistCreation()
                                }
                        }
                    }
                }
                .padding(.horizontal, isLandscape ? 0 : 12)
                }
                
                if selectedChip.type == .create {
                    emptyView
                } else if case .playlist(let playlistID) = selectedChip.type {
                    playlistHeaderView(playlistID: playlistID)
                    if filteredResults.isEmpty {
                        emptyView
                    } else {
                        resultsView
                    }
                } else if filteredResults.isEmpty {
                    emptyView
                } else {
                    resultsView
                }
                
                Spacer()
            }
        }
        .onAppear {
            for playlist in playlistService.getPlaylistOrder() {
                if !playlist.isSystem {
                    playlistService.loadPlaylistTracks(playlistID: playlist.id, page: 0)
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            ExpandableSearchBar(
                text: $searchText,
                placeholder: "Поиск треков и плейлистов",
                onSubmit: {
                    performSearch()
                },
                onClear: {
                    playlistService.searchTracks(query: nil) { _ in }
                }
            )

            Spacer()
                .frame(width: isLandscape ? 0 : 54)
        }
    }
    
    private var resultsView: some View {
        ScrollView {
            if isLandscape && selectedChip.type == .photos {
                HStack(alignment: .top, spacing: 2) {
                    ForEach(0..<2, id: \.self) { columnIndex in
                        VStack(spacing: 2) {
                            ForEach(photoItemsForColumn(columnIndex), id: \.id) { track in
                                TrackCardView(
                                    track: track,
                                    onTap: {
                                        ModalProvider.shared.show(PhotoViewModal(track: track, isReadOnly: true), requiresBackground: false, disableDismissOnTap: true)
                                    },
                                    onLongPress: {
                                    showPhotoInfo(track)
                                }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 8)
            } else if isLandscape {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                    ForEach(filteredResults, id: \.id) { track in
                        trackView(for: track)
                    }
                }
                .padding(.horizontal, 8)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredResults, id: \.id) { track in
                        trackView(for: track)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 16)
    }
    
    private func trackView(for track: Track) -> some View {
            let contentType = track.contentType?.lowercased() ?? ""
        return TrackCardView(
            track: track,
            onTap: {
            if contentType == "image" {
                    ModalProvider.shared.show(PhotoViewModal(track: track), requiresBackground: false, disableDismissOnTap: true)
                } else {
                    QueueService.shared.playTrack(track)
                    HistoryService.shared.recordPlayed(track)
                }
            },
            onLongPress: {
                if contentType == "audio" {
                    showMusicInfo(track)
                } else if contentType == "image" {
                    showPhotoInfo(track)
                } else {
                    showVideoInfo(track)
                }
            }
        )
    }
    
    private var photoItems: [Track] {
        filteredResults.filter { track in
            track.contentType?.lowercased() == "image"
        }
    }
    
    private func photoItemsForColumn(_ columnIndex: Int) -> [Track] {
        photoItems.enumerated().compactMap { index, track in
            index % 2 == columnIndex ? track : nil
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .tint(themeObserver.themedAccentColor)
                .padding()
            
            Text("Загрузка...")
                .foregroundColor(themeObserver.themedPrimaryColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "music.note.list" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(themeObserver.themedAccentColor)
            
            Text(searchText.isEmpty ? "Плейлисты" : "Ничего не найдено")
                .font(.headline)
                .foregroundColor(themeObserver.themedPrimaryColor)
            
            Text(searchText.isEmpty ?
                 "Выберите фильтр для просмотра контента" :
                 "Попробуйте изменить запрос или фильтр")
                .font(.body)
                .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func performSearch() {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        playlistService.searchTracks(query: q.isEmpty ? nil : q) { _ in }
    }
    
    private func showVideoInfo(_ track: Track) {
        ModalProvider.shared.showModalContainer(EditVideoModal(track: track))
    }
    
    private func showMusicInfo(_ track: Track) {
        ModalProvider.shared.showModalContainer(EditMusicModal(track: track))
    }
    
    private func showPhotoInfo(_ track: Track) {
        ModalProvider.shared.showModalContainer(EditPhotoModal(track: track, isReadOnly: false))
    }
    
    @State private var editingPlaylistName: String = ""
    
    private func playlistHeaderView(playlistID: UUID) -> some View {
        VStack(spacing: 16) {
            if let playlist = playlistService.getPlaylist(by: playlistID) {
                TextField("Название плейлиста", text: Binding(
                    get: { editingPlaylistName.isEmpty ? playlist.name : editingPlaylistName },
                    set: { editingPlaylistName = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .onAppear {
                    if editingPlaylistName.isEmpty {
                        editingPlaylistName = playlist.name
                    }
                }
                .onChange(of: playlist.name) { newName in
                    if editingPlaylistName == playlist.name {
                        editingPlaylistName = newName
                    }
                }
                .onSubmit {
                    let trimmedName = editingPlaylistName.trimmingCharacters(in: .whitespaces)
                    if !trimmedName.isEmpty && trimmedName != playlist.name {
                        playlistService.renamePlaylist(id: playlistID, newName: trimmedName)
                    }
                }
                
                HStack(spacing: 16) {
                    WideButton(
                        title: "Удалить плейлист",
                        action: {
                            playlistService.deletePlaylist(id: playlistID)
                            selectedChip = PlaylistChipItem(type: .all)
                        },
                        isEnabled: true
                    )
                    
                    WideButton(
                        title: "Добавить треки",
                        action: {
                            // TODO: Добавить функционал
                        },
                        isEnabled: true
                    )
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func startPlaylistCreation() {
        playlistService.createPlaylist(name: "Новый плейлист")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let newPlaylist = playlistService.getPlaylistOrder()
                .first(where: { !isSystemPlaylist($0.id) && $0.name == "Новый плейлист" }) {
                editingPlaylistName = newPlaylist.name
                selectedChip = PlaylistChipItem(type: .playlist(newPlaylist.id))
            }
        }
    }
    
    
    private func isSystemPlaylist(_ id: UUID) -> Bool {
        return id == PlaylistService.likedPlaylistID || 
               id == PlaylistService.videosPlaylistID || 
               id == PlaylistService.musicPlaylistID || 
               id == PlaylistService.photosPlaylistID
    }
}

#Preview {
    PlaylistsView()
}
