//
//  ThemeSettings.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 25.10.2025.
//

import SwiftUI

struct ThemeSettings: Codable {
    var lightAccentColor: CodableColor
    var darkAccentColor: CodableColor
    var lightPrimaryColor: CodableColor
    var darkPrimaryColor: CodableColor
    var lightSecondaryColor: CodableColor
    var darkSecondaryColor: CodableColor
    var lightTextColor: CodableColor
    var darkTextColor: CodableColor
    
    var lightBackgroundColor: CodableColor
    var darkBackgroundColor: CodableColor
    var backgroundImageName: String?
    var enableBackgroundBlur: Bool
    
    static let `default` = ThemeSettings(
        // Светлая тема - контрастная, но не токсичная палитра
        lightAccentColor: CodableColor(Color(red: 70/255, green: 90/255, blue: 130/255)), // Насыщенный тёмно-синий
        darkAccentColor: CodableColor(Color(red: 95/255, green: 179/255, blue: 211/255)), 
        lightPrimaryColor: CodableColor(Color(red: 50/255, green: 70/255, blue: 110/255)), // Глубокий тёмно-синий
        darkPrimaryColor: CodableColor(Color(red: 74/255, green: 155/255, blue: 200/255)), 
        lightSecondaryColor: CodableColor(Color(red: 235/255, green: 235/255, blue: 240/255)), // Нейтральный светло-серый
        darkSecondaryColor: CodableColor(Color(red: 30/255, green: 42/255, blue: 53/255)), 
        lightTextColor: CodableColor(Color(red: 25/255, green: 25/255, blue: 30/255)), // Почти чёрный для контраста
        darkTextColor: CodableColor(Color(red: 232/255, green: 240/255, blue: 245/255)), 
        lightBackgroundColor: CodableColor(Color(red: 248/255, green: 248/255, blue: 250/255)), // Нейтральный почти белый
        darkBackgroundColor: CodableColor(Color(red: 15/255, green: 20/255, blue: 25/255)), // Очень тёмный серо-синий
        
        backgroundImageName: nil,
        enableBackgroundBlur: true
    )
}

struct CodableColor: Codable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
    
    init(_ color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
