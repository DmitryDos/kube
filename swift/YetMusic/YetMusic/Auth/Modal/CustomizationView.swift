import SwiftUI
import PhotosUI

struct CustomizationView: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @ObservedObject private var settingsService = ThemeSettingsService.shared
    @State private var selectedColorItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @StateObject private var alertState = AlertState()
    @State private var savedSettings: ThemeSettings?

    private var cancelButton: AnyView? {
        AnyView(
            WideButton(
                title: "Отменить",
                action: handleCancel,
            )
        )
    }

    func handleCancel() {
        if let savedSettings {
            settingsService.settings = savedSettings
            settingsService.saveSettings()
        }
        ModalProvider.shared.dismiss()
    }

    func handleReset() {
        showConfirmation(
            title: "Сброс настроек",
            message: "Вы уверены, что хотите сбросить все настройки темы к значениям по умолчанию?",
            alertState: alertState
        ) {
            settingsService.resetToDefaults()
        }
    }

    var body: some View {
        ModalContainer(
            title: "Кастомизация",
            leftButton: AnyView(
                IconButton(
                    systemName: "arrow.clockwise",
                    action: handleReset,
                    color: themeObserver.themedAccentColor
                )
            ),
            bottomButton: cancelButton
        ) {
            ScrollView {
                VStack(spacing: 20) {
                    WideButton(
                        title: themeObserver.isDarkTheme ? "Светлая тема" : "Тёмная тема",
                        action: { themeObserver.toggleTheme() },
                        isFilled: false,
                        textColor: themeObserver.themedAccentColor,
                        showBorder: false
                    )

                    CustomColorPicker(
                        title: "Акцентный цвет",
                        selectedColor: Binding(
                            get: {
                                themeObserver.isDarkTheme
                                ? settingsService.settings.darkAccentColor.color
                                : settingsService.settings.lightAccentColor.color
                            },
                            set: { newColor in
                                if themeObserver.isDarkTheme {
                                    settingsService.settings.darkAccentColor = CodableColor(newColor)
                                } else {
                                    settingsService.settings.lightAccentColor = CodableColor(newColor)
                                }
                                settingsService.saveSettings()
                            }
                        )
                    )
                    
                    CustomColorPicker(
                        title: "Основной цвет",
                        selectedColor: Binding(
                            get: {
                                themeObserver.isDarkTheme
                                ? settingsService.settings.lightPrimaryColor.color
                                : settingsService.settings.darkPrimaryColor.color
                            },
                            set: { newColor in
                                if themeObserver.isDarkTheme {
                                    settingsService.settings.lightPrimaryColor = CodableColor(newColor)
                                } else {
                                    settingsService.settings.darkPrimaryColor = CodableColor(newColor)
                                }
                                settingsService.saveSettings()
                            }
                        )
                    )

                    CustomColorPicker(
                        title: "Вторичный цвет",
                        selectedColor: Binding(
                            get: {
                                themeObserver.isDarkTheme
                                ? settingsService.settings.darkSecondaryColor.color
                                : settingsService.settings.lightSecondaryColor.color
                            },
                            set: { newColor in
                                if themeObserver.isDarkTheme {
                                    settingsService.settings.darkSecondaryColor = CodableColor(newColor)
                                } else {
                                    settingsService.settings.lightSecondaryColor = CodableColor(newColor)
                                }
                                settingsService.saveSettings()
                            }
                        )
                    )

                    CustomColorPicker(
                        title: "Цвет текста",
                        selectedColor: Binding(
                            get: {
                                themeObserver.isDarkTheme
                                ? settingsService.settings.darkTextColor.color
                                : settingsService.settings.lightTextColor.color
                            },
                            set: { newColor in
                                if themeObserver.isDarkTheme {
                                    settingsService.settings.darkTextColor = CodableColor(newColor)
                                } else {
                                    settingsService.settings.lightTextColor = CodableColor(newColor)
                                }
                                settingsService.saveSettings()
                            }
                        )
                    )
                    
                    CustomColorPicker(
                        title: "Цвет фона",
                        selectedColor: Binding(
                            get: {
                                themeObserver.isDarkTheme
                                ? settingsService.settings.darkBackgroundColor.color
                                : settingsService.settings.lightBackgroundColor.color
                            },
                            set: { newColor in
                                if themeObserver.isDarkTheme {
                                    settingsService.settings.darkBackgroundColor = CodableColor(newColor)
                                } else {
                                    settingsService.settings.lightBackgroundColor = CodableColor(newColor)
                                }
                                settingsService.saveSettings()
                            }
                        )
                    )

                    PhotosPicker(
                        selection: $selectedColorItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            Image(systemName: "photo")
                            Text("Выбрать фон")
                            Spacer()
                            if themeObserver.backgroundImageName != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(themeObserver.successColor)
                            }
                        }
                        .padding()
                        .background(themeObserver.contrastColor)
                        .foregroundColor(themeObserver.themedAccentColor)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(themeObserver.primaryGlassColor, lineWidth: 1)
                        )
                    }
                    .onChange(of: selectedColorItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                await MainActor.run {
                                    if let image = UIImage(data: data) {
                                        saveBackgroundImage(image)
                                    }
                                }
                            }
                        }
                    }

                    if themeObserver.backgroundImageName != nil {
                        WideButton(
                            title: "Удалить фон",
                            action: { removeBackgroundImage() },
                            isFilled: false,
                            textColor: themeObserver.themedPrimaryColor
                        )
                    }

                    Toggle("Размытие фона", isOn: Binding(
                        get: { settingsService.settings.enableBackgroundBlur },
                        set: {
                            settingsService.settings.enableBackgroundBlur = $0
                            settingsService.saveSettings()
                        }
                    ))
                    .padding(.horizontal)
                    .background(themeObserver.contrastColor)
                    .foregroundColor(themeObserver.themedAccentColor)
                    .cornerRadius(10)
                    .tint(themeObserver.themedAccentColor)
                }
            }
        }
        .onAppear {
            savedSettings = settingsService.settings
        }
        .confirmationDialog(alertState)
    }

    private func saveBackgroundImage(_ image: UIImage) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "custom_background_\(Date().timeIntervalSince1970).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        if let data = image.jpegData(compressionQuality: 0.8) {
            do {
                try data.write(to: fileURL)
                settingsService.settings.backgroundImageName = fileName
                settingsService.saveSettings()
            } catch {
                print("Ошибка сохранения фона: \(error)")
            }
        }
    }

    private func removeBackgroundImage() {
        if let oldImageName = settingsService.settings.backgroundImageName {
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let oldFileURL = documentsDirectory.appendingPathComponent(oldImageName)
            do {
                try fileManager.removeItem(at: oldFileURL)
            } catch {
                print("Ошибка удаления старого фона: \(error)")
            }
        }
        settingsService.settings.backgroundImageName = nil
        settingsService.saveSettings()
    }
}
