import SwiftUI

struct EditTrackModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    
    let title: String
    let content: AnyView
    let onSave: (() -> Void)?
    let onDelete: (() -> Void)?
    let canEdit: Bool
    
    @StateObject private var alertState = AlertState()
    
    init(
        title: String,
        content: AnyView,
        canEdit: Bool = true,
        onSave: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.title = title
        self.content = content
        self.canEdit = canEdit
        self.onSave = onSave
        self.onDelete = onDelete
    }
    
    private var saveButton: AnyView? {
        guard canEdit, let onSave = onSave else { return nil }
        return AnyView(
            WideButton(
                title: "Сохранить",
                action: {
                    onSave()
                    ModalProvider.shared.dismiss()
                },
                isEnabled: true
            )
            .padding(.horizontal)
        )
    }
    
    private var leftButton: AnyView? {
        guard canEdit, let onDelete = onDelete else { return nil }
        return AnyView(
            IconButton(
                systemName: "trash",
                action: {
                    showConfirmation(
                        title: "Удалить",
                        message: "Вы уверены, что хотите удалить?",
                        alertState: alertState
                    ) {
                        onDelete()
                        ModalProvider.shared.dismiss()
                    }
                }
            )
        )
    }
    
    var body: some View {
        ModalContainer(
            title: title,
            leftButton: leftButton,
            bottomButton: saveButton
        ) {
            content
        }
        .confirmationDialog(alertState)
    }
}
