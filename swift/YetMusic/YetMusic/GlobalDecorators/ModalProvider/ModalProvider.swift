import SwiftUI

struct ModalItem {
    let view: AnyView
    let onClose: (() -> Void)?
    let requiresBackground: Bool
    let isModalContainer: Bool
    let disableDismissOnTap: Bool
}

class ModalProvider: ObservableObject {
    static let shared = ModalProvider()
    
    @Published var modals: [ModalItem] = []

    private init() {}

    func show<Content: View>(_ modal: Content, onClose: (() -> Void)? = nil, requiresBackground: Bool = true, isModalContainer: Bool = false, disableDismissOnTap: Bool = false) {
        let item = ModalItem(view: AnyView(modal), onClose: onClose, requiresBackground: requiresBackground, isModalContainer: isModalContainer, disableDismissOnTap: disableDismissOnTap)
        modals.append(item)
    }

    func replace<Content: View>(_ modal: Content, onClose: (() -> Void)? = nil, requiresBackground: Bool = true, isModalContainer: Bool = false, disableDismissOnTap: Bool = false) {
        guard let last = modals.popLast() else {
            let item = ModalItem(view: AnyView(modal), onClose: onClose, requiresBackground: requiresBackground, isModalContainer: isModalContainer, disableDismissOnTap: disableDismissOnTap)
            modals.append(item)
            return
        }
        last.onClose?()
        let item = ModalItem(view: AnyView(modal), onClose: onClose, requiresBackground: requiresBackground, isModalContainer: isModalContainer, disableDismissOnTap: disableDismissOnTap)
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
    
    // Helper для показа модалок с ModalContainer
    func showModalContainer<Content: View>(_ modal: Content, onClose: (() -> Void)? = nil, requiresBackground: Bool = true) {
        show(modal, onClose: onClose, requiresBackground: requiresBackground, isModalContainer: true)
    }
}

struct ModalProviderView: View {
    @StateObject private var modalProvider = ModalProvider.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @StateObject private var orientation = OrientationObserver()

    var body: some View {
        ZStack {
            // Стеклянный фон на весь экран для вертикального режима (игнорирует клики)
            // Показываем только если есть хотя бы одна модалка, требующая фон
            let modalsRequiringBackground = modalProvider.modals.filter { $0.requiresBackground }.count
            if !orientation.isLandscape && modalsRequiringBackground > 0 {
                themeObserver.backgroundGlassColor
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            
            ForEach(Array(modalProvider.modals.enumerated()), id: \.offset) { index, item in
                let isActive = index == modalProvider.modals.count - 1
                let isLast = index == modalProvider.modals.count - 1
                // Если модалок больше 1, любой тач закрывает модалку
                // Если модалка последняя (одна) и это не ModalContainer, тач прокидывается
                // Если это ModalContainer, даже если он один, клики не прокидываются
                let shouldBlockClicks = modalProvider.modals.count > 1 || item.isModalContainer
                
                ModalBackground(
                    onBackgroundTap: {
                        if !item.disableDismissOnTap {
                        closeModal(at: index)
                        }
                    },
                    isActive: isActive,
                    blocksClicks: shouldBlockClicks
                ) {
                    item.view
                        .environment(\.isLandscape, orientation.isLandscape)
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
