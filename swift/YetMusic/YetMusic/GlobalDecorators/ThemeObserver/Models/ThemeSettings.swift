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
        lightAccentColor: CodableColor(.purple),
        darkAccentColor: CodableColor(.orange),
        lightPrimaryColor: CodableColor(Color(red: 205/255, green: 102/255, blue: 0)),
        darkPrimaryColor: CodableColor(Color.blue),
        lightSecondaryColor: CodableColor(Color(red: 1.0, green: 0.96, blue: 0.96)),
        darkSecondaryColor: CodableColor(Color(red: 0.15, green: 0.05, blue: 0.15)),
        lightTextColor: CodableColor(Color(red: 0.1, green: 0.1, blue: 0.1)),
        darkTextColor: CodableColor(.white),
        lightBackgroundColor: CodableColor(.white),
        darkBackgroundColor: CodableColor(.black),
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
