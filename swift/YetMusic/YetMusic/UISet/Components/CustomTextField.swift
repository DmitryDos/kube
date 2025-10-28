//
//  CustomTextField.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 25.10.2025.
//

import SwiftUI

struct CustomTextField: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let title: String
    @Binding var text: String
    let systemImage: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(themeObserver.themedAccentColor)
                
                if isSecure {
                    SecureField(title, text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .keyboardType(keyboardType)
                        .foregroundColor(themeObserver.textColor)
                } else {
                    TextField(title, text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .foregroundColor(themeObserver.textColor)
                }
            }
            .padding(10)
            .background(themeObserver.primaryGlassColor)
            .cornerRadius(50)
        }
    }
}
