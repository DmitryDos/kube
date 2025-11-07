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
    var isEditable: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeObserver.primaryGlassColor)
            }
            
            if isEditable {
                TextField(placeholder, text: $text)
                    .padding()
                    .background(themeObserver.secondaryGlassColor)
                    .foregroundColor(themeObserver.textColor)
                    .cornerRadius(10)
                    .onChange(of: text) { _ in
                        onChange?()
                    }
            } else {
                Text(text.isEmpty ? placeholder : text)
                    .padding()
                    .background(themeObserver.secondaryGlassColor.opacity(0.5))
                    .foregroundColor(themeObserver.textColor.opacity(0.7))
                    .cornerRadius(10)
            }
        }
    }
}
