import SwiftUI

struct ShowTrackInfoModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let track: Track
    @State private var editedTitle: String
    @State private var editedArtist: String
    @State private var hasChanges: Bool = false
    @StateObject private var alertState = AlertState()
    
    init(track: Track) {
        self.track = track
        self._editedTitle = State(initialValue: track.title)
        self._editedArtist = State(initialValue: track.artist)
    }

    private var saveButton: AnyView? {
        AnyView(
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
            title: "Редактировать трек",
            leftButton: AnyView(
                IconButton(
                    systemName: "trash",
                    action: handleDelete,
                )
            ),
            bottomButton: saveButton
        ) {
            VStack(spacing: 20) {
                AsyncTrackImage(
                    track: track,
                    cornerRadius: 12
                )

                VStack(spacing: 16) {
                    TextFieldWithLabel(
                        title: "Название",
                        placeholder: "",
                        text: $editedTitle,
                        onChange: checkForChanges
                    )
                    
                    TextFieldWithLabel(
                        title: "Исполнитель",
                        placeholder: "",
                        text: $editedArtist,
                        onChange: checkForChanges
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
    }

    private func checkForChanges() {
        hasChanges = editedTitle != track.title || editedArtist != track.artist
    }
    
    private func saveChanges() {
        TrackController.shared.updateTrackMetadata(
            track: track,
            newTitle: editedTitle,
            newArtist: editedArtist
        )
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
