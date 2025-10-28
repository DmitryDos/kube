//
//  ActionGridButton.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 24.10.2025.
//

import SwiftUI

struct ActionGridButton: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeObserver.contrastColor)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeObserver.textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 70, height: 80)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
