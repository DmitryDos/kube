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
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try? container.decode(Date.self, forKey: .createdAt)
        
        // Декодируем id как UUID из строки
        let idString = try container.decode(String.self, forKey: .id)
        guard let uuid = UUID(uuidString: idString) else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, 
                debugDescription: "Invalid UUID string: \(idString)")
        }
        id = uuid
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(name, forKey: .name)
        if let createdAt = createdAt {
            try container.encode(createdAt, forKey: .createdAt)
        }
    }
    
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
