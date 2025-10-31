import SwiftUI

struct FullPlayerView: View {
    @Environment(\.isLandscape) private var isLandscape

    var body: some View {
        Group {
            if isLandscape {
                HorizontalPlayerView()
            } else {
                VerticalPlayerView()
            }
        }
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
