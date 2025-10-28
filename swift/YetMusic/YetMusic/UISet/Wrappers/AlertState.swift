//
//  AlertState.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 20.10.2025.
//

import SwiftUI

class AlertState: ObservableObject {
    @Published var isShowing = false
    @Published var title: String = ""
    @Published var message: String = ""
    @Published var onConfirm: (() -> Void)? = nil
}

struct ConfirmationDialogModifier: ViewModifier {
    @ObservedObject var alertState: AlertState
    
    func body(content: Content) -> some View {
        content
            .alert(alertState.title, isPresented: $alertState.isShowing) {
                Button("Отмена", role: .cancel) { }
                Button("Подтвердить", role: .destructive) {
                    alertState.onConfirm?()
                }
            } message: {
                Text(alertState.message)
            }
    }
}

extension View {
    func confirmationDialog(_ alertState: AlertState) -> some View {
        self.modifier(ConfirmationDialogModifier(alertState: alertState))
    }
}

func showConfirmation(
    title: String,
    message: String,
    alertState: AlertState,
    onConfirm: @escaping () -> Void
) {
    alertState.title = title
    alertState.message = message
    alertState.onConfirm = onConfirm
    alertState.isShowing = true
}
