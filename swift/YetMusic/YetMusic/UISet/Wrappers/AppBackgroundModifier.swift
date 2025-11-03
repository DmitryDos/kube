//
//  AppBackgroundModifier.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 22.10.2025.
//

import SwiftUICore

struct AppBackgroundModifier: ViewModifier {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let cornerRadius: CGFloat = 14.0
    let padding: CGFloat
    let strokeLineWidth: CGFloat = 1.5
    
    init(padding: CGFloat = 16.0) {
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(themeObserver.backgroundGlassColor.blur(radius: 2))
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(themeObserver.contrastColor, lineWidth: 2)
            )
    }
}

extension View {
    func appBackground(padding: CGFloat = 16.0) -> some View {
        self.modifier(AppBackgroundModifier(padding: padding))
    }
}
