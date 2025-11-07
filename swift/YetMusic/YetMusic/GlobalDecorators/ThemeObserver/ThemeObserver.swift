//
//  ThemeObserver.swift
//  YetMusic
//

import SwiftUI

class ThemeObserver: ObservableObject {
    @Published var isDarkTheme: Bool = true
    @Published var settings: ThemeSettings = ThemeSettingsService.shared.settings
        
    static let shared = ThemeObserver()

    init() {
        ThemeSettingsService.shared.$settings
            .assign(to: &$settings)
    }

    func toggleTheme() {
        withAnimation {
            isDarkTheme.toggle()
        }
    }

    var accentColor: Color {
        isDarkTheme ? settings.darkAccentColor.color : settings.lightAccentColor.color
    }
    
    var themedAccentColor: Color {
        accentColor
    }
    
    var primaryColor: Color {
        settings.lightPrimaryColor.color
    }
    var darkPrimaryColor: Color {
        settings.darkPrimaryColor.color
    }
    var themedPrimaryColor: Color {
        isDarkTheme ? primaryColor : darkPrimaryColor
    }
    
    var secondaryColor: Color {
        isDarkTheme ? settings.darkSecondaryColor.color : settings.lightSecondaryColor.color
    }
    
    var darkColor: Color {
        settings.darkSecondaryColor.color
    }
    
    var contrastColor: Color {
        isDarkTheme ? darkColor : secondaryColor
    }
    
    let lightGlassColor = Color(red: 0.95, green: 0.85, blue: 0.95).opacity(0.6)
    let darkGlassColor = Color(red: 0.15, green: 0.05, blue: 0.15).opacity(0.6)
    var primaryGlassColor: Color {
        isDarkTheme ? lightGlassColor : darkGlassColor
    }

    var secondaryGlassColor: Color {
        isDarkTheme ? darkGlassColor : lightGlassColor
    }
    
    var backgroundColor: Color {
        isDarkTheme ? settings.darkBackgroundColor.color : settings.lightBackgroundColor.color
    }
    
    var backgroundGlassColor: Color {
        isDarkTheme ? lightGlassColor : darkGlassColor
    }
    
    var backgroundAccentColor: Color {
        primaryColor.opacity(0.5)
    }
    
    var textColor: Color {
        isDarkTheme ? settings.darkTextColor.color : settings.lightTextColor.color
    }
    
    var lightTextColor: Color {
        settings.lightTextColor.color
    }
    
    var darkTextColor: Color {
        settings.darkTextColor.color
    }

    var backgroundImage: Image? {
        if let customImage = loadCustomBackground() {
            return Image(uiImage: customImage)
        }

        if let imageName = settings.backgroundImageName,
           let uiImage = UIImage(named: imageName) {
            return Image(uiImage: uiImage)
        }

        return nil
    }
        
    var backgroundImageName: String? {
        settings.backgroundImageName
    }
    
    var enableBackgroundBlur: Bool {
        settings.enableBackgroundBlur
    }
    
    private func loadCustomBackground() -> UIImage? {
        guard let imageName = settings.backgroundImageName else { return nil }

        if imageName.hasPrefix("custom_background") {
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent(imageName)
            
            if fileManager.fileExists(atPath: fileURL.path),
               let imageData = try? Data(contentsOf: fileURL),
               let image = UIImage(data: imageData) {
                return image
            }
        }
        return nil
    }
}

private struct DarkThemeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var darkTheme: Bool {
        get { self[DarkThemeKey.self] }
        set { self[DarkThemeKey.self] = newValue }
    }
}

extension View {
    func darkTheme(_ enabled: Bool) -> some View {
        environment(\.darkTheme, enabled)
    }
}
