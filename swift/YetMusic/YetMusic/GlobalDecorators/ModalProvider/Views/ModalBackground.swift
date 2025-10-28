//
//  ModalBackground.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 26.10.2025.
//

import SwiftUI

class ModalBackgroundUIView: UIView {
    var onBackgroundTap: () -> Void = {}
    var isActive: Bool = true

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isActive else {
            return self
        }
        
        let instances = ModalMarkerUIView.instances.allObjects

        for modal in instances {
            let modalPoint = modal.convert(point, from: self)
            
            if modal.bounds.contains(modalPoint) {
                return nil
            }
        }
        
        onBackgroundTap()
        return nil
    }
}

struct ModalBackground<Content: View>: View {
    let onBackgroundTap: () -> Void
    let content: Content
    @State private var marker: ModalMarkerUIView?
    let isActive: Bool

    init(onBackgroundTap: @escaping () -> Void, isActive: Bool = true, @ViewBuilder content: () -> Content) {
        self.onBackgroundTap = onBackgroundTap
        self.isActive = isActive
        self.content = content()
    }

    var body: some View {
        ZStack {
            GestureDetector(onBackgroundTap: onBackgroundTap, isActive: isActive)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            content
        }
    }
}
