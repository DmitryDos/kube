import SwiftUI

struct FullPlayerView: View {
    @Environment(\.isLandscape) private var isLandscape
    @ObservedObject private var ui = UIStateService.shared

    var body: some View {
        Group {
            if isLandscape {
                HorizontalPlayerView()
            } else {
                VerticalPlayerView()
            }
        }
        .onAppear { if isLandscape { ui.isFullPlayerVisible = true } }
        .onDisappear { if isLandscape { ui.isFullPlayerVisible = false } }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
