//
//  AuthFormView.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 25.10.2025.
//

import SwiftUI

struct AuthFormView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isRegistering = false
    
    @Environment(\.isLandscape) private var isLandscape
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: isRegistering ? "person.crop.circle.badge.plus" : "person.crop.circle")
                .font(.system(size: 80))
                .foregroundColor(themeObserver.themedAccentColor)
            
            Text(isRegistering ? "Регистрация" : "Вход в YetMusic")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeObserver.themedAccentColor)

            VStack(spacing: 20) {
                if isRegistering {
                    CustomTextField(
                        title: "Имя",
                        text: $name,
                        systemImage: "person"
                    )
                }
                
                CustomTextField(
                    title: "Email",
                    text: $email,
                    systemImage: "envelope",
                    keyboardType: .emailAddress
                )
                
                CustomTextField(
                    title: "Пароль",
                    text: $password,
                    systemImage: "lock",
                    isSecure: true
                )
                
                Button(action: handleAuth) {
                    HStack {
                        Spacer()
                        Text(isRegistering ? "Зарегистрироваться" : "Войти")
                            .font(.headline)
                            .foregroundColor(themeObserver.themedAccentColor)
                        Spacer()
                    }
                    .padding()
                    .background(authButtonColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeObserver.themedAccentColor, lineWidth: isFormValid ? 1 : 0)
                    )
                }
                .disabled(!isFormValid)
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isRegistering.toggle()
                        clearForm()
                    }
                }) {
                    Text(isRegistering ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться")
                        .font(.subheadline)
                        .foregroundColor(themeObserver.primaryGlassColor)
                }
            }
            .padding(.horizontal, 32)
            
            if let error = authService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(themeObserver.errorColor)
                    .padding()
                    .background(themeObserver.errorColor.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 32)
                    .transition(.opacity)
            }
            
            Spacer()
        }
        .padding(.horizontal, isLandscape ? 60 : 0)
        .padding(.top, 20)
    }
    
    private var isFormValid: Bool {
        if isRegistering {
            return !name.isEmpty && !email.isEmpty && email.contains("@") && !password.isEmpty && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    private var authButtonColor: Color {
        isFormValid ? themeObserver.contrastColor : themeObserver.contrastColor.opacity(0.5)
    }
    
    private func handleAuth() {
        if isRegistering {
            authService.register(email: email, password: password, name: name)
        } else {
            authService.login(email: email, password: password)
        }
        
        if authService.isAuthenticated {
            clearForm()
        }
    }
    
    private func clearForm() {
        password = ""
        name = ""
        email = ""
    }
}
