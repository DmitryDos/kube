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
            .background(
                RoundedRectangle(cornerRadius: cornerRadius + 6)
                    .fill(themeObserver.contrastColor)
            )
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius + 6)
                    .fill(themeObserver.backgroundGlassColor)
                    .stroke(themeObserver.darkColor, lineWidth: strokeLineWidth)
            )
    }
}

extension View {
    func appBackground(padding: CGFloat = 16.0) -> some View {
        self.modifier(AppBackgroundModifier(padding: padding))
    }
}
