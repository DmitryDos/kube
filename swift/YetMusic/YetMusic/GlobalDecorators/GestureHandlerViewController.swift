import SwiftUI
import UIKit



// MARK: - SwiftUI представление для детектора
struct GestureDetector: UIViewRepresentable {
    var onBackgroundTap: () -> Void
    var isActive: Bool = true
    
    func makeUIView(context: Context) -> ModalBackgroundUIView {
        let view = ModalBackgroundUIView()
        view.onBackgroundTap = onBackgroundTap
        view.isActive = isActive
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: ModalBackgroundUIView, context: Context) {
        uiView.onBackgroundTap = onBackgroundTap
        uiView.isActive = isActive
    }
}
