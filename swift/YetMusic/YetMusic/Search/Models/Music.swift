//
//  Music.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import Foundation

struct Music: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let artist: String
    let coverURL: String?
    let duration: TimeInterval?
    let genre: String?
    let year: Int?
    let description: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        coverURL: String? = nil,
        duration: TimeInterval? = nil,
        genre: String? = nil,
        year: Int? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.coverURL = coverURL
        self.duration = duration
        self.genre = genre
        self.year = year
        self.description = description
    }
}

