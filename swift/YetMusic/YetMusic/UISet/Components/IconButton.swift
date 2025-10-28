//
//  IconButton.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 20.10.2025.
//

import SwiftUI

struct IconButton: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let systemName: String
    let action: () -> Void
    var color: Color? = nil
    var fontSize: CGFloat = 16
    var fontWeight: Font.Weight = .medium
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(color ?? themeObserver.themedAccentColor)
                .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
