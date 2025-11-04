//
//  User.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 27.09.2025.
//

import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let name: String
    
    var initials: String {
        name.prefix(1).uppercased()
    }
}

struct AuthResponse: Codable {
    let message: String
    let user: User
    let token: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
}
