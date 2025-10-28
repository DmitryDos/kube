//
//  DetailRow.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 19.10.2025.
//

import SwiftUICore
import SwiftUI

struct DetailRow: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(themeObserver.primaryGlassColor)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(themeObserver.textColor)
        }
    }
}
