import SwiftUI

struct ShowTrackInfoModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let track: Track
    let isReadOnly: Bool
    @State private var editedTitle: String
    @State private var editedArtist: String
    @State private var hasChanges: Bool = false
    @StateObject private var alertState = AlertState()
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
        self._editedArtist = State(initialValue: track.artist)
    }

    private var saveButton: AnyView? {
        guard canEdit else { return nil }
        return AnyView(
            WideButton(
                title: "Сохранить",
                action: {
                    saveChanges()
                    ModalProvider.shared.dismiss()
                },
                isEnabled: hasChanges
            )
            .padding(.horizontal)
        )
    }
    
    private var leftButton: AnyView? {
        guard canEdit else { return nil }
        return AnyView(
            IconButton(
                systemName: "trash",
                action: handleDelete,
            )
        )
    }
    
    func handleDelete() {
        showConfirmation(
            title: "Удалить трек",
            message: "Вы уверены, что хотите удалить \"\(track.title)\"?",
            alertState: alertState
        ) {
            do {
                try TrackController.shared.deleteTrack(track)
            } catch {}
            ModalProvider.shared.dismiss()
        }
    }
    
    var body: some View {
        ModalContainer(
            title: canEdit ? "Редактировать трек" : "Информация о треке",
            leftButton: leftButton,
            bottomButton: saveButton
        ) {
            VStack(spacing: 20) {
                // Обложка с возможностью загрузки
                ZStack(alignment: .bottomTrailing) {
                    if let thumbnail = selectedThumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .cornerRadius(12)
                            .clipped()
                    } else {
                        AsyncTrackImage(
                            track: track,
                            cornerRadius: 12
                        )
                        .frame(height: 200)
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
                
                VStack(spacing: 8) {
                    DetailRow(title: "Длительность", value: formatDuration(track.duration))
                    DetailRow(title: "Добавлен", value: formatDate(track.dateAdded))
                }
                .padding()
                .cornerRadius(12)
            }
        }
        .confirmationDialog(alertState)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedThumbnail)
        }
    }

    private func checkForChanges() {
        hasChanges = editedTitle != track.title || editedArtist != track.artist || selectedThumbnail != nil
    }
    
    private func saveChanges() {
        TrackController.shared.updateTrackMetadata(
            track: track,
            newTitle: editedTitle,
            newArtist: editedArtist
        )
        
        if let videoID = track.remoteVideoId {
            Task {
                do {
                    if let updatedVideo = try await VideoService.shared.updateVideoMetadata(
                        videoID: videoID,
                        title: editedTitle,
                        description: editedArtist,
                        thumbnail: selectedThumbnail
                    ) {
                        // Обновляем трек с новым thumbnailURL
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
