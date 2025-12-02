import SwiftUI

struct EditVideoModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let track: Track
    let isReadOnly: Bool
    
    @State private var editedTitle: String
    @State private var editedDescription: String
    @State private var hasChanges: Bool = false
    @State private var selectedThumbnail: UIImage?
    @State private var showImagePicker: Bool = false
    
    private var isOwner: Bool {
        guard let ownerId = track.ownerUserId,
              let currentUserId = AuthService.shared.currentUser?.id else {
            return false
        }
        return ownerId == currentUserId
    }
    
    private var canEdit: Bool {
        !isReadOnly && isOwner
    }
    
    init(track: Track, isReadOnly: Bool = false) {
        self.track = track
        self.isReadOnly = isReadOnly
        self._editedTitle = State(initialValue: track.title)
        self._editedDescription = State(initialValue: track.desc)
    }
    
    func handleDelete() {
        do {
            try TrackController.shared.deleteTrack(track)
        } catch {}
    }
    
    var body: some View {
        let content = AnyView(
            VStack(spacing: 20) {
                ZStack(alignment: .bottomTrailing) {
                    if let thumbnail = selectedThumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .cornerRadius(12)
                            .clipped()
                    } else {
                        GeometryReader { geometry in
                            AsyncTrackImage(track: track, canOpenModal: true)
                                .frame(width: geometry.size.width, height: 200)
                                .aspectRatio(16/9, contentMode: .fill)
                                .clipped()
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
                        title: "Описание",
                        placeholder: "",
                        text: $editedDescription,
                        onChange: checkForChanges,
                        isEditable: canEdit
                    )
                }
                
                VStack(spacing: 8) {
                    if track.duration > 0 {
                        DetailRow(title: "Длительность", value: formatDuration(track.duration))
                    }
                    DetailRow(title: "Добавлен", value: formatDate(track.dateAdded))
                }
                .padding()
                .cornerRadius(12)
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedThumbnail)
            }
        )
        
        return EditTrackModal(
            title: canEdit ? "Редактировать видео" : "Информация о видео",
            content: content,
            canEdit: canEdit,
            onSave: canEdit ? { saveChanges() } : nil,
            onDelete: canEdit ? { handleDelete() } : nil
        )
    }
    
    private func checkForChanges() {
        hasChanges = editedTitle != track.title || editedDescription != track.desc || selectedThumbnail != nil
    }
    
    private func saveChanges() {
        TrackController.shared.updateTrackMetadata(
            track: track,
            newTitle: editedTitle,
            newDescription: editedDescription
        )
        
        Task {
            do {
                if let updatedVideo = try await VideoService.shared.updateVideoMetadata(
                    videoID: track.id,
                    title: editedTitle,
                    description: editedDescription,
                    thumbnail: selectedThumbnail
                ) {
                    await MainActor.run {
                        if let index = TrackController.shared.tracks.firstIndex(where: { $0.id == track.id }) {
                            TrackController.shared.tracks[index].thumbnailURL = updatedVideo.thumbnailURL
                            TrackRepository().updateTrackMetadata(track: TrackController.shared.tracks[index])
                        }
                    }
                }
            } catch {
                print("Failed to update video metadata: \(error)")
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

