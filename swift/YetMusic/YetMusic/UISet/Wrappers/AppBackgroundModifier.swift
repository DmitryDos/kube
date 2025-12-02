//
//  AppBackgroundModifier.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 22.10.2025.
//

import SwiftUI

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
            .background {
                ZStack {
                    // Базовый стеклянный фон с blur - более выразительный
                    themeObserver.backgroundGlassColor
                        .blur(radius: 12)
                    
                    // Полупрозрачный overlay для универсального контраста
                    // Белый overlay на тёмной теме, чёрный на светлой
                    themeObserver.whiteColor.opacity(themeObserver.isDarkTheme ? 0.2 : 0.3)
                    
                    // Дополнительный чёрный overlay для глубины
                    themeObserver.blackColor.opacity(themeObserver.isDarkTheme ? 0.15 : 0.08)
                }
            }
            .cornerRadius(cornerRadius)
            .overlay(
                // Обводка без внутренних теней
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        themeObserver.whiteColor.opacity(themeObserver.isDarkTheme ? 0.5 : 0.6),
                        lineWidth: 1.5
                    )
            )
    }
}

extension View {
    func appBackground(padding: CGFloat = 16.0) -> some View {
        self.modifier(AppBackgroundModifier(padding: padding))
    }
}
