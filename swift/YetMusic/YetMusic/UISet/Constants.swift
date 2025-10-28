//
//  Constants.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 22.10.2025.
//

//import SwiftUI
//
//enum AppColors {
//    static let accentColor = Color.orange
//    static let primaryColor = Color(red: 205/255, green: 102/255, blue: 0)
//    static let secondaryColor = Color(red: 1.0, green: 0.96, blue: 0.96)
//    static let darkColor = Color(red: 0.15, green: 0.05, blue: 0.15)
//    
//    static let darkGlassColor = Color(red: 0.15, green: 0.05, blue: 0.15)
//        .opacity(0.6)
//    static let lightGlassColor = Color(red: 0.95, green: 0.85, blue: 0.95)
//        .opacity(0.6)
//    
//    static func backgroundColor(isDarkTheme: Bool) -> Color {
//        isDarkTheme ? Color(red: 0, green: 0, blue: 0) : Color.white
//    }
//    static let backgroundAccentColor = darkColor;
//
//    static let textColor = Color(red: 0.1, green: 0.1, blue: 0.1)
//}
//
//
//class ThemeColors: ObservableObject {
//    @Published var isDarkTheme: Bool = false
//    
//    var backgroundColor: Color {
//        isDarkTheme ? .black : .white
//    }
//    
//}
//
//private struct ThemeColorsKey: EnvironmentKey {
//    static let defaultValue = ThemeColors()
//}
//
//extension EnvironmentValues {
//    var themeColors: ThemeColors {
//        get { self[ThemeColorsKey.self] }
//        set { self[ThemeColorsKey.self] = newValue }
//    }
//}
