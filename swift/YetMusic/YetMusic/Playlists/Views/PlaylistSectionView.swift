import SwiftUI

struct PlaylistSectionView: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    
    let title: String
    let tracks: [Track]
    let isSystem: Bool
    var isEditingMode: Bool = false
    var showSelectionToggles: Bool = false
    @Binding var selectedTracks: Set<UUID>
    @Binding var tempPlaylistName: String
    let onSavePlaylist: () -> Void
    let onDeletePlaylist: (() -> Void)?
    let onTrackLongPress: (Track) -> Void
    let onPlaylistLongPress: () -> Void
    
    @State private var isExpanded: Bool = false
    @State private var showDeleteAlert = false

    @State private var currentWidth: CGFloat = 0
    
    private var gridColumns: [GridItem] {
        if currentWidth > 600 {
            return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        } else if currentWidth > 300 {
            return [GridItem(.flexible()), GridItem(.flexible())]
        } else {
            return [GridItem(.flexible())]
        }
    }
    
    init(title: String, tracks: [Track], isSystem: Bool, isEditingMode: Bool, showSelectionToggles: Bool, selectedTracks: Binding<Set<UUID>>, tempPlaylistName: Binding<String>, onSavePlaylist: @escaping () -> Void, onDeletePlaylist: (() -> Void)?, onTrackLongPress: @escaping (Track) -> Void, onPlaylistLongPress: @escaping () -> Void) {
        self.title = title
        self.tracks = tracks
        self.isSystem = isSystem
        self.isEditingMode = isEditingMode
        self.showSelectionToggles = showSelectionToggles
        self._selectedTracks = selectedTracks
        self._tempPlaylistName = tempPlaylistName
        self.onSavePlaylist = onSavePlaylist
        self.onDeletePlaylist = onDeletePlaylist
        self.onTrackLongPress = onTrackLongPress
        self.onPlaylistLongPress = onPlaylistLongPress
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !isEditingMode {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    headerContent
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .onLongPressGesture {
                    if !isSystem && !isEditingMode {
                        onPlaylistLongPress()
                    }
                }
            } else {
                headerContent
            }
            
            if isExpanded {
                if tracks.isEmpty && !isEditingMode {
                    emptyStateView
                } else {
                    // УБИРАЕМ GeometryReader и используем другой подход
                    gridContent
                        .padding(.top, 12)
                }
            }
        }
        .padding(.top, 12)
        .background(
            // Добавляем GeometryReader здесь для отслеживания ширины
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        currentWidth = geometry.size.width
                    }
                    .onChange(of: geometry.size.width) { newWidth in
                        currentWidth = newWidth
                    }
            }
        )
        .onAppear {
            if isEditingMode {
                isExpanded = true
            }
        }
        .onChange(of: isEditingMode) { editing in
            if editing {
                isExpanded = true
            }
        }
        .alert("Удалить плейлист", isPresented: $showDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                onDeletePlaylist?()
            }
        } message: {
            Text("Вы уверены, что хотите удалить \"\(title)\"?")
        }
    }

    private var headerContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isEditingMode {
                editingHeader
            } else {
                normalHeader
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeObserver.contrastColor)
                .opacity(isExpanded ? 0.01 : 1)
        )
        .contentShape(Rectangle())
        .onLongPressGesture {
            if !isSystem && !isEditingMode {
                onPlaylistLongPress()
            }
        }
    }
    
    private var normalHeader: some View {
        HStack {
            HStack {
                if !isSystem {
                    IconButton(
                        systemName: "pencil",
                        action: onPlaylistLongPress
                    )
                }
     
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeObserver.themedPrimaryColor)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeObserver.contrastColor)
            )

            Spacer()
            
            if isSystem {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(themeObserver.themedAccentColor)
            }
            
            Image(systemName: "chevron.down")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeObserver.themedAccentColor)
                .rotationEffect(.degrees(isExpanded ? 0 : -90))
                .padding(.horizontal, 16)
        }
    }
    
    private var editingHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                TextFieldWithLabel(
                    title: nil,
                    placeholder: "Название плейлиста",
                    text: $tempPlaylistName
                )
                
                if !isSystem {
                    IconButton(
                        systemName: "trash",
                        action: { showDeleteAlert = true },
                    )
                } else {
                    Spacer()
                        .frame(width: 30, height: 30)
                }
            }
            
            HStack {
                Button("Сохранить") {
                    onSavePlaylist()
                }
                .foregroundColor(themeObserver.themedAccentColor)
                .font(.headline.weight(.semibold))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeObserver.contrastColor)
                )
                
                Spacer()
            }
            .padding(.horizontal, 12)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 40))
                .foregroundColor(.white)
            
            if isEditingMode {
                Text("Выберите треки из других плейлистов")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            } else {
                Text("Тут ничего нет")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }
    
    private func toggleTrackSelection(_ track: Track) {
        if selectedTracks.contains(track.id) {
            selectedTracks.remove(track.id)
        } else {
            selectedTracks.insert(track.id)
        }
    }

    private var gridContent: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(tracks) { track in
                PlaylistTrackView(
                    track: track,
                    isEditingMode: showSelectionToggles,
                    isSelected: selectedTracks.contains(track.id),
                    onToggle: {
                        toggleTrackSelection(track)
                    },
                    onLongPress: {
                        onTrackLongPress(track)
                    }
                )
            }
        }
    }
}
