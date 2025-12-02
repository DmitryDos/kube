import SwiftUI

struct EditMusicModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let track: Track
    let isReadOnly: Bool
    
    @State private var editedTitle: String
    @State private var editedArtist: String
    @State private var hasChanges: Bool = false
    @State private var selectedCover: UIImage?
    @State private var showImagePicker: Bool = false
    
    private var canEdit: Bool {
        !isReadOnly
    }
    
    init(track: Track, isReadOnly: Bool = false) {
        self.track = track
        self.isReadOnly = isReadOnly
        self._editedTitle = State(initialValue: track.title)
        self._editedArtist = State(initialValue: track.desc)
    }
    
    func handleDelete() {
        Task {
            do {
                try await VideoService.shared.deleteVideo(videoID: track.id)
            } catch {
                print("Failed to delete music: \(error)")
            }
        }
    }
    
    var body: some View {
        let content = AnyView(
            VStack(spacing: 20) {
                ZStack(alignment: .bottomTrailing) {
                    if let cover = selectedCover {
                        Image(uiImage: cover)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .cornerRadius(12)
                            .clipped()
                    } else {
                        AsyncImage(url: track.imageURL) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(themeObserver.contrastColor)
                                    .overlay(ProgressView().tint(themeObserver.themedAccentColor))
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Rectangle()
                                    .fill(themeObserver.contrastColor)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.system(size: 40))
                                            .foregroundColor(themeObserver.textColor.opacity(0.5))
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(height: 200)
                        .cornerRadius(12)
                        .clipped()
                    }
                    
                    if canEdit {
                        Button {
                            showImagePicker = true
                        } label: {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(themeObserver.themedAccentColor)
                                .cornerRadius(8)
                        }
                        .padding(8)
                    }
                }
                
                VStack(spacing: 16) {
                    TextFieldWithLabel(
                        title: "Название",
                        placeholder: "",
                        text: $editedTitle,
                        onChange: checkForChanges,
                        isEditable: canEdit
                    )
                    
                    TextFieldWithLabel(
                        title: "Исполнитель",
                        placeholder: "",
                        text: $editedArtist,
                        onChange: checkForChanges,
                        isEditable: canEdit
                    )
                }
                
                if track.duration > 0 {
                    VStack(spacing: 8) {
                        DetailRow(title: "Длительность", value: formatDuration(track.duration))
                    }
                    .padding()
                    .cornerRadius(12)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedCover)
            }
        )
        
        return EditTrackModal(
            title: canEdit ? "Редактировать музыку" : "Информация о музыке",
            content: content,
            canEdit: canEdit,
            onSave: canEdit ? { saveChanges() } : nil,
            onDelete: canEdit ? { handleDelete() } : nil
        )
    }
    
    private func checkForChanges() {
        hasChanges = editedTitle != track.title || editedArtist != track.desc || selectedCover != nil
    }
    
    private func saveChanges() {
        Task {
            do {
                try await UploadService.shared.updateMusicMetadata(
                    musicID: track.id,
                    title: editedTitle,
                    artist: editedArtist,
                    cover: selectedCover
                )
            } catch {
                print("Failed to update music metadata: \(error)")
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

