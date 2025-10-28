//
//  ProfileSettingsView.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 25.10.2025.
//

import SwiftUI

struct ProfileSettingsView: View {
    @ObservedObject var authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }
    
    var body: some View {
        ModalContainer(
            title: "Профиль",
        ) {
            VStack(spacing: 16) {
                Text("Настройки профиля")
                    .font(.headline)
                Text("Скоро будет доступно...")
                    .foregroundColor(.secondary)
            }
        }
    }
}
