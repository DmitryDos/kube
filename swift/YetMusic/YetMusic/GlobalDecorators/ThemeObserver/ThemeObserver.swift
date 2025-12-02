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
    
    // Glass colors - обновлены под новую палитру, лучше сочетаются с темами
    let lightGlassColor = Color(red: 235/255, green: 235/255, blue: 240/255).opacity(0.7)
    let darkGlassColor = Color(red: 30/255, green: 42/255, blue: 53/255).opacity(0.7)
    
    // Error and success colors
    var errorColor: Color {
        isDarkTheme ? Color(red: 255/255, green: 107/255, blue: 107/255) : Color(red: 220/255, green: 53/255, blue: 69/255)
    }
    
    var successColor: Color {
        isDarkTheme ? Color(red: 72/255, green: 199/255, blue: 116/255) : Color(red: 40/255, green: 167/255, blue: 69/255)
    }
    
    var likeColor: Color {
        isDarkTheme ? Color(red: 255/255, green: 107/255, blue: 107/255) : Color(red: 220/255, green: 53/255, blue: 69/255)
    }
    
    var whiteColor: Color {
        isDarkTheme ? Color(red: 255/255, green: 255/255, blue: 255/255) : Color(red: 255/255, green: 255/255, blue: 255/255)
    }
    
    var blackColor: Color {
        isDarkTheme ? Color(red: 0/255, green: 0/255, blue: 0/255) : Color(red: 0/255, green: 0/255, blue: 0/255)
    }
    var primaryGlassColor: Color {
        isDarkTheme ? darkGlassColor : lightGlassColor
    }

    var secondaryGlassColor: Color {
        isDarkTheme ? lightGlassColor : darkGlassColor
    }
    
    var backgroundColor: Color {
        isDarkTheme ? settings.darkBackgroundColor.color : settings.lightBackgroundColor.color
    }
    
    var backgroundGlassColor: Color {
        isDarkTheme ? darkGlassColor : lightGlassColor
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
