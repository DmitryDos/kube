import SwiftUI

struct AuthModal: View {
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isRegistering = false
    
    var body: some View {
        ModalContainer(
            title: isRegistering ? "Регистрация" : "Вход в YetMusic"
        ) {
            VStack(spacing: 24) {
                Image(systemName: isRegistering ? "person.crop.circle.badge.plus" : "person.crop.circle")
                    .font(.system(size: 60))
                    .foregroundColor(themeObserver.themedAccentColor)
                    .padding(.top, 8)
                
                VStack(spacing: 16) {
                    if isRegistering {
                        TextFieldWithLabel(
                            title: "Имя",
                            placeholder: "Введите имя",
                            text: $name
                        )
                    }
                    
                    TextFieldWithLabel(
                        title: "Email",
                        placeholder: "Введите email",
                        text: $email
                    )
                    
                    TextFieldWithLabel(
                        title: "Пароль",
                        placeholder: "Введите пароль",
                        text: $password
                    )
                    
                    WideButton(
                        title: isRegistering ? "Зарегистрироваться" : "Войти",
                        action: handleAuth,
                        isEnabled: isFormValid
                    )
                    .padding(.top, 8)
                    
                    Button(action: {
                        withAnimation {
                            isRegistering.toggle()
                            clearForm()
                        }
                    }) {
                        Text(isRegistering ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться")
                            .font(.subheadline)
                            .foregroundColor(themeObserver.themedAccentColor)
                    }
                    .padding(.top, 4)
                }
                
                if let error = authService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(themeObserver.errorColor)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(themeObserver.errorColor.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                ModalProvider.shared.dismiss()
            }
        }
    }
    
    private var isFormValid: Bool {
        if isRegistering {
            return !name.isEmpty && !email.isEmpty && email.contains("@") && !password.isEmpty && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    private func handleAuth() {
        if isRegistering {
            authService.register(email: email, password: password, name: name)
        } else {
            authService.login(email: email, password: password)
        }
    }
    
    private func clearForm() {
        password = ""
        name = ""
        email = ""
    }
}

