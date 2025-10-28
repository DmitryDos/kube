//
//  TextFieldWithLabel.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 20.10.2025.
//

import SwiftUICore
import SwiftUI

struct TextFieldWithLabel: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let title: String?
    let placeholder: String
    @Binding var text: String
    var onChange: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeObserver.primaryGlassColor)
            }
            
            TextField(placeholder, text: $text)
                .padding()
                .background(themeObserver.secondaryGlassColor)
                .foregroundColor(themeObserver.textColor)
                .cornerRadius(10)
                .onChange(of: text) { _ in
                    onChange?()
                }
        }
    }
}
