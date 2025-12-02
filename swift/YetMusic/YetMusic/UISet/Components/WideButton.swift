//
//  WideButton.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 20.10.2025.
//

import SwiftUI

struct WideButton: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isFilled: Bool = true
    var backgroundColor: Color? = nil
    var textColor: Color? = nil
    var showBorder: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(textColor ?? (isFilled ? themeObserver.whiteColor : themeObserver.textColor))
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.vertical, isFilled ? 12 : 12)
                .background(isFilled ? backgroundColor ?? themeObserver.themedAccentColor : Color.clear)
                .opacity(isEnabled ? 1 : 0.6)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isFilled || !showBorder ? Color.clear : (textColor ?? themeObserver.textColor), lineWidth: 1.5)
                )
        }
        .disabled(!isEnabled)
        .buttonStyle(ScaleButtonStyle())
    }
}
