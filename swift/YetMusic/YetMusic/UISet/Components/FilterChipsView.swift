// FilterChipsView.swift
import SwiftUI

struct FilterChipsView<T: Hashable & CustomStringConvertible>: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    
    let items: [T]
    @Binding var selectedItem: T
    let onSelectionChanged: (T) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    FilterChip(
                        title: item.description,
                        isSelected: selectedItem == item,
                        action: {
                            selectedItem = item
                            onSelectionChanged(item)
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

struct FilterChip: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(isSelected ? themeObserver.whiteColor : themeObserver.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? themeObserver.themedAccentColor : themeObserver.contrastColor)
                )
        }
        .buttonStyle(PressableButtonStyle())
    }
}
