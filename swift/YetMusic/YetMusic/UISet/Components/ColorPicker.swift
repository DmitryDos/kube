//
//  CustomColorPicker.swift
//  YetMusic
//

import SwiftUI

struct CustomColorPicker: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let title: String
    @Binding var selectedColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(themeObserver.primaryGlassColor)
            
            Button(action: {
                showColorPickerModal()
            }) {
                HStack {
                    Circle()
                        .fill(selectedColor)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(themeObserver.primaryGlassColor, lineWidth: 1)
                        )
                    
                    Text("Выбрать цвет")
                        .foregroundColor(themeObserver.themedAccentColor)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(themeObserver.primaryGlassColor)
                }
                .padding()
                .background(themeObserver.contrastColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeObserver.primaryGlassColor, lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    private func showColorPickerModal() {
        ModalProvider.shared.show(
            ColorPickerModalView(selectedColor: $selectedColor, title: title)
        )
    }
}

struct ColorPickerModalView: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Binding var selectedColor: Color
    let title: String
    @State private var tempSelectedColor: Color
    
    init(selectedColor: Binding<Color>, title: String) {
        self._selectedColor = selectedColor
        self._tempSelectedColor = State(initialValue: selectedColor.wrappedValue)
        self.title = title
    }
    
    private var confirmButton: AnyView {
        AnyView(
            WideButton(
                title: "Подтвердить",
                action: {
                    selectedColor = tempSelectedColor
                    ModalProvider.shared.dismiss()
                },
            )
            .padding(.horizontal)
        )
    }
    
    var body: some View {
        ModalContainer(
            title: title,
            leftButton: nil,
            bottomButton: confirmButton
        ) {
            VStack(spacing: 20) {
                ColorPicker("Выберите цвет", selection: $tempSelectedColor, supportsOpacity: false)
                    .padding()
                    .foregroundColor(themeObserver.textColor)
                    .background(themeObserver.contrastColor)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(themeObserver.primaryGlassColor, lineWidth: 1)
                    )

                Text("Быстрые цвета")
                    .font(.headline)
                    .foregroundColor(themeObserver.themedAccentColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(quickColors, id: \.self) { color in
                        Button(action: {
                            tempSelectedColor = color
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(themeObserver.primaryGlassColor, lineWidth: 2)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: tempSelectedColor == color ? 3 : 0)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }

                HStack {
                    Text("Текущий выбор:")
                        .foregroundColor(themeObserver.textColor)
                    Spacer()
                    Circle()
                        .fill(tempSelectedColor)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(themeObserver.primaryGlassColor, lineWidth: 2)
                        )
                }
                .padding()
                .background(themeObserver.contrastColor)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(themeObserver.primaryGlassColor, lineWidth: 1)
                )
                
                Spacer()
            }
        }
    }
    
    private var quickColors: [Color] {
        [
            .red, .orange, .yellow, .green, .mint, .teal,
            .cyan, .blue, .indigo, .purple, .pink, .brown,
            .white, .gray, .black
        ]
    }
}
