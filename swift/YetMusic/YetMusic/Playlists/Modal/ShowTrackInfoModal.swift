import SwiftUI

struct ShowTrackInfoModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let track: Track
    let isReadOnly: Bool
    @State private var editedTitle: String
    @State private var editedDescription: String
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
        self._editedDescription = State(initialValue: track.desc)
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
        var buttons: [AnyView] = []
        
        // Кнопка редактирования (показываем всегда, если есть тип контента)
        let contentType = track.contentType?.lowercased() ?? ""
        if contentType == "video" {
            buttons.append(AnyView(
                Button {
                    ModalProvider.shared.showModalContainer(EditVideoModal(track: track, isReadOnly: false))
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(themeObserver.themedAccentColor)
                }
            ))
        } else if contentType == "audio" {
            buttons.append(AnyView(
                Button {
                    ModalProvider.shared.showModalContainer(MusicEditModal(track: track, audioURL: nil))
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(themeObserver.themedAccentColor)
                }
            ))
        }
        
        // Кнопка удаления
        if canEdit {
            buttons.append(AnyView(
                IconButton(
                    systemName: "trash",
                    action: handleDelete,
                )
            ))
        }
        
        if buttons.isEmpty {
            return nil
        }
        
        return AnyView(
            HStack(spacing: 12) {
                ForEach(0..<buttons.count, id: \.self) { index in
                    buttons[index]
                }
            }
        )
    }
    
    func handleDelete() {
        showConfirmation(
            title: "Удалить трек",
            message: "Вы уверены, что хотите удалить \"\(track.title)\"?",
            alertState: alertState
        ) {
            Task {
            do {
                try TrackController.shared.deleteTrack(track)
                    await MainActor.run {
            ModalProvider.shared.dismiss()
                    }
                } catch {
                    print("Failed to delete music: \(error)")
                    await MainActor.run {
                        // Можно показать ошибку пользователю
                    }
                }
            }
        }
    }
    
    var body: some View {
        ModalContainer(
            title: canEdit ? "Редактировать трек" : "Информация о треке",
            leftButton: leftButton,
            bottomButton: saveButton
        ) {
            VStack(spacing: 20) {
                // Кнопка редактирования выше обложки
                let contentType = track.contentType?.lowercased() ?? ""
                if contentType == "video" {
                    Button {
                        ModalProvider.shared.showModalContainer(EditVideoModal(track: track, isReadOnly: false))
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                                .font(.system(size: 16, weight: .medium))
                            Text("Редактировать видео")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(themeObserver.themedAccentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(themeObserver.backgroundGlassColor)
                        .cornerRadius(12)
                    }
                } else if contentType == "audio" {
                    Button {
                        ModalProvider.shared.showModalContainer(MusicEditModal(track: track, audioURL: nil))
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                                .font(.system(size: 16, weight: .medium))
                            Text("Редактировать аудио")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(themeObserver.themedAccentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(themeObserver.backgroundGlassColor)
                        .cornerRadius(12)
                    }
                }
                
                Group {
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
                            cornerRadius: 12,
                            imageContentMode: .fit,
                            canOpenModal: true
                        )
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .overlay(
                            ModalMarkerView()
                                .allowsHitTesting(false)
                        )
                        .overlay(alignment: .bottomTrailing) {
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
                                .overlay(
                                    ModalMarkerView()
                                        .allowsHitTesting(false)
                                )
                            }
                        }
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
