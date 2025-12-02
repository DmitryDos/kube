import SwiftUI

struct EditPhotoModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let track: Track
    let isReadOnly: Bool
    
    @State private var editedTitle: String
    @State private var editedDescription: String
    @State private var hasChanges: Bool = false
    
    private var isOwner: Bool {
        if track.ownerUserId == nil {
            return true
        }
        guard let ownerId = track.ownerUserId,
              let currentUserId = AuthService.shared.currentUser?.id else {
            return false
        }
        return ownerId == currentUserId
    }
    
    private var canEdit: Bool {
        let result = !isReadOnly
        print("[EditPhotoModal] canEdit: \(result), isReadOnly: \(isReadOnly)")
        return result
    }
    
    private var imageURL: URL? {
        return track.imageURL
    }
    
    init(track: Track, isReadOnly: Bool = false) {
        self.track = track
        self.isReadOnly = isReadOnly
        self._editedTitle = State(initialValue: track.title)
        self._editedDescription = State(initialValue: track.desc)
    }
    
    func handleDelete() {
        Task {
            do {
                try await VideoService.shared.deleteVideo(videoID: track.id)
                await MainActor.run {
                    PlaylistService.shared.removeTrackFromAllPlaylists(trackId: track.id)
                }
            } catch {
                print("[EditPhotoModal] Failed to delete photo: \(error)")
            }
        }
    }
    
    var body: some View {
        let content = AnyView(
            VStack(spacing: 20) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(themeObserver.themedAccentColor)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(themeObserver.textColor.opacity(0.5))
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    ModalProvider.shared.show(PhotoViewModal(track: track, isReadOnly: false), requiresBackground: false, disableDismissOnTap: true)
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
            }
        )
        
        let canShowButtons = canEdit && isOwner
        print("[EditPhotoModal] canShowButtons: \(canShowButtons), canEdit: \(canEdit), isOwner: \(isOwner), isReadOnly: \(isReadOnly)")
        return EditTrackModal(
            title: canShowButtons ? "Редактировать фото" : "Информация о фото",
            content: content,
            canEdit: canShowButtons,
            onSave: canShowButtons ? { saveChanges() } : nil,
            onDelete: canShowButtons ? { handleDelete() } : nil
        )
    }
    
    private func checkForChanges() {
        hasChanges = editedTitle != track.title || editedDescription != track.desc
    }
    
    private func saveChanges() {
        Task {
            do {
                try await UploadService.shared.updatePhotoMetadata(
                    photoID: track.id,
                    title: editedTitle.isEmpty ? nil : editedTitle,
                    description: editedDescription.isEmpty ? nil : editedDescription
                )
            } catch {
                print("Failed to update photo metadata: \(error)")
            }
        }
    }
}

