import SwiftUI

struct ModalItem {
    let view: AnyView
    let onClose: (() -> Void)?
}

class ModalProvider: ObservableObject {
    static let shared = ModalProvider()
    
    @Published var modals: [ModalItem] = []

    private init() {}

    func show<Content: View>(_ modal: Content, onClose: (() -> Void)? = nil) {
        let item = ModalItem(view: AnyView(modal), onClose: onClose)
        modals.append(item)
    }

    func replace<Content: View>(_ modal: Content, onClose: (() -> Void)? = nil) {
        guard let last = modals.popLast() else {
            let item = ModalItem(view: AnyView(modal), onClose: onClose)
            modals.append(item)
            return
        }
        last.onClose?()
        let item = ModalItem(view: AnyView(modal), onClose: onClose)
        modals.append(item)
    }

    func dismiss() {
        guard let last = modals.popLast() else { return }
        last.onClose?()
    }

    func dismissAll() {
        while let item = modals.popLast() {
            item.onClose?()
        }
    }
}

struct ModalProviderView: View {
    @StateObject private var modalProvider = ModalProvider.shared

    var body: some View {
        ZStack {
            ForEach(Array(modalProvider.modals.enumerated()), id: \.offset) { index, item in
                let isActive = index == modalProvider.modals.count - 1
                
                ModalBackground(
                    onBackgroundTap: {
                        closeModal(at: index)
                    },
                    isActive: isActive
                ) {
                    item.view
                        .zIndex(Double(index))
                }
            }
        }
    }
    
    private func closeModal(at index: Int) {
        let modalsToRemove = modalProvider.modals.count - index
        for _ in 0..<modalsToRemove {
            modalProvider.dismiss()
        }
    }
}

extension View {
    func withModalProvider() -> some View {
        ZStack {
            self
            ModalProviderView()
        }
    }
}
