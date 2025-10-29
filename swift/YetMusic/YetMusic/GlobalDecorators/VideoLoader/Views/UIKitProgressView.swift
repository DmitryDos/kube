import SwiftUI
import UIKit

struct UIKitProgressView: UIViewRepresentable {
    var progress: Float
    var tintColor: UIColor = .systemBlue

    func makeUIView(context: Context) -> UIProgressView {
        let view = UIProgressView(progressViewStyle: .default)
        view.progressTintColor = tintColor
        return view
    }

    func updateUIView(_ uiView: UIProgressView, context: Context) {
        uiView.setProgress(progress, animated: true)
    }
}


