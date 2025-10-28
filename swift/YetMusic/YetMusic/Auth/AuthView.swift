//
//  AuthView.swift
//  YetMusic
//

import SwiftUI

struct AuthView: View {
    @ObservedObject var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                ProfileView(authService: authService)
            } else {
                AuthFormView(authService: authService)
            }
        }
    }
}
