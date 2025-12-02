import SwiftUI
import UIKit



// MARK: - SwiftUI представление для детектора
struct GestureDetector: UIViewRepresentable {
    var onBackgroundTap: () -> Void
    var isActive: Bool = true
    var blocksClicks: Bool = false
    
    func makeUIView(context: Context) -> ModalBackgroundUIView {
        let view = ModalBackgroundUIView()
        view.onBackgroundTap = onBackgroundTap
        view.isActive = isActive
        view.blocksClicks = blocksClicks
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: ModalBackgroundUIView, context: Context) {
        uiView.onBackgroundTap = onBackgroundTap
        uiView.isActive = isActive
        uiView.blocksClicks = blocksClicks
    }
}
