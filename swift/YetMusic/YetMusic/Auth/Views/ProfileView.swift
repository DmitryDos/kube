//
//  ProfileView.swift
//  YetMusic
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @StateObject private var alertState = AlertState()
    
    enum ProfileTab: CaseIterable {
        case statistics, customization, profile
        
        var title: String {
            switch self {
            case .statistics: return "Статистика"
            case .customization: return "Кастомизация"
            case .profile: return "Профиль"
            }
        }
        
        var icon: String {
            switch self {
            case .statistics: return "chart.bar.fill"
            case .customization: return "paintbrush.fill"
            case .profile: return "person.fill"
            }
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Circle()
                        .fill(LinearGradient(
                            colors: [themeObserver.themedAccentColor, themeObserver.primaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(authService.currentUser?.name.prefix(1).uppercased() ?? "U")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(radius: 10)
                    
                    VStack(spacing: 8) {
                        Text(authService.currentUser?.name ?? "Пользователь")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeObserver.themedAccentColor)
                        
                        Text(authService.currentUser?.email ?? "email@example.com")
                            .font(.body)
                            .foregroundColor(themeObserver.primaryGlassColor)
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 30)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(ProfileTab.allCases, id: \.self) { tab in
                        Button(action: {
                            showModalForTab(tab)
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(themeObserver.themedAccentColor)
                                
                                Text(tab.title)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(themeObserver.themedAccentColor)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(themeObserver.contrastColor)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(themeObserver.themedAccentColor, lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Кнопка выхода с AlertState
                Button(action: {
                    showConfirmation(
                        title: "Выход из аккаунта",
                        message: "Вы уверены, что хотите выйти?",
                        alertState: alertState
                    ) {
                        authService.logout()
                    }
                }) {
                    Text("Выйти из аккаунта")
                        .font(.headline)
                        .foregroundColor(themeObserver.themedAccentColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeObserver.contrastColor)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeObserver.themedAccentColor, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 30)
            }
        }
        .confirmationDialog(alertState)
    }
    
    private func showModalForTab(_ tab: ProfileTab) {
        switch tab {
        case .statistics:
            ModalProvider.shared.show(
                StatisticsView()
            )
        case .customization:
            ModalProvider.shared.show(
                CustomizationView()
            )
            
        case .profile:
            ModalProvider.shared.show(
                ProfileSettingsView(authService: authService)
            )
        }
    }
}

struct StatCard: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(themeObserver.themedAccentColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(themeObserver.primaryGlassColor)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeObserver.themedAccentColor)
            }
            
            Spacer()
        }
        .padding()
        .background(themeObserver.contrastColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeObserver.primaryGlassColor, lineWidth: 1)
        )
    }
}
