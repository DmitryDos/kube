//
//  ThemeSettingsService.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 25.10.2025.
//

import Foundation

class ThemeSettingsService: ObservableObject {
    static let shared = ThemeSettingsService()
    
    @Published var settings: ThemeSettings = .default
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "themeSettings"
    
    private init() {
        loadSettings()
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
    }
    
    private func loadSettings() {
        guard let data = userDefaults.data(forKey: settingsKey),
              let decoded = try? JSONDecoder().decode(ThemeSettings.self, from: data) else {
            settings = .default
            return
        }
        settings = decoded
    }
    
    func resetToDefaults() {
        settings = .default
        saveSettings()
    }
}
