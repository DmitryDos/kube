//
//  OrientationLock.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import UIKit
import SwiftUI

class OrientationLock {
    static func rotateToLandscape() {
        // Переключаем ориентацию устройства
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
        
        // Принудительно обновляем через UIApplication для гарантии
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscape)
            windowScene.requestGeometryUpdate(geometryPreferences) { error in
                // Игнорируем ошибки
            }
        }
        
        // Обновляем OrientationObserver
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    static func rotateToPortrait() {
        // Переключаем ориентацию устройства
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        
        // Принудительно обновляем через UIApplication для гарантии
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
            windowScene.requestGeometryUpdate(geometryPreferences) { error in
                // Игнорируем ошибки
            }
        }
        
        // Обновляем OrientationObserver
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: nil)
    }
}

