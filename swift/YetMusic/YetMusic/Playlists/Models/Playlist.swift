//
//  Playlist.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 25.10.2025.
//

import SwiftData
import Foundation

@Model
final class Playlist {
    var id: UUID
    var name: String
    var isSystem: Bool
    var tracks: [Track]
    
    init(id: UUID = UUID(), name: String, isSystem: Bool = false) {
        self.id = id
        self.name = name
        self.isSystem = isSystem
        self.tracks = []
    }
}
