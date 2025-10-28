//
//  ModalMarkerUIView.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 25.10.2025.
//

import UIKit
import SwiftUI

class ModalMarkerUIView: UIView {
    static var instances = NSHashTable<ModalMarkerUIView>.weakObjects()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        ModalMarkerUIView.instances.add(self)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        ModalMarkerUIView.instances.add(self)
    }
}

struct ModalMarkerUIViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> ModalMarkerUIView {
        let view = ModalMarkerUIView()
        return view
    }
    
    func updateUIView(_ uiView: ModalMarkerUIView, context: Context) {}
}

struct ModalMarkerView: View {
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .background(
                    ModalMarkerUIViewRepresentable()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                )
        }
    }
}
