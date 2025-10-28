import SwiftUI

struct PageScrollReader: UIViewRepresentable {
    @Binding var offset: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator(offset: $offset) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            if let scrollView = findScrollView(in: view) {
                scrollView.delegate = context.coordinator
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView { return scrollView }
        for subview in view.subviews {
            if let found = findScrollView(in: subview) { return found }
        }
        return nil
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        @Binding var offset: CGFloat
        init(offset: Binding<CGFloat>) { _offset = offset }
        func scrollViewDidScroll(_ scrollView: UIScrollView) { offset = scrollView.contentOffset.x }
    }
}
