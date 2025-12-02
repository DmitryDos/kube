import SwiftUI

struct QueueSideModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared

    private var safeAreaLeading: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.left
        }
        return 0
    }

    var body: some View {
        CompactQueueView()
    }
}


