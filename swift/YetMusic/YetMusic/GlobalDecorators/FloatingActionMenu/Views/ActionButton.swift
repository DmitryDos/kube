//
//  ActionButton.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 24.10.2025.
//

import SwiftUI

struct ActionButton: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    init(title: String, icon: String, color: Color = .blue, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
}
