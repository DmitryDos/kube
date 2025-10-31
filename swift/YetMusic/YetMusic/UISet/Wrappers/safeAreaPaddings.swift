//
//  safeAreaPaddings.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 31.10.2025.
//

import SwiftUICore

extension View {
    func constrainedToSafeArea() -> some View {
        self.modifier(ConstrainedToSafeAreaModifier())
    }
}

struct ConstrainedToSafeAreaModifier: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets
            let availableWidth = geometry.size.width - safeArea.leading - safeArea.trailing
            let availableHeight = geometry.size.height - safeArea.top - safeArea.bottom
            
            content
                .frame(
                    maxWidth: availableWidth,
                    maxHeight: availableHeight
                )
        }
    }
}
