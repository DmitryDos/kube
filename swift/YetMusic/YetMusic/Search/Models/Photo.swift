//
//  Photo.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import Foundation

struct Photo: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String?
    let imageURL: String
    let width: Int
    let height: Int
    let author: String?
    let description: String?
    let tags: [String]?
    let publishedDate: Date?
    let ownerUserId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case imageURL = "image_url"
        case width
        case height
        case author
        case description
        case tags
        case publishedDate = "published_date"
        case ownerUserId = "user_id"
    }
    
    init(
        id: UUID = UUID(),
        title: String? = nil,
        imageURL: String,
        width: Int,
        height: Int,
        author: String? = nil,
        description: String? = nil,
        tags: [String]? = nil,
        publishedDate: Date? = nil,
        ownerUserId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.width = width
        self.height = height
        self.author = author
        self.description = description
        self.tags = tags
        self.publishedDate = publishedDate
        self.ownerUserId = ownerUserId
    }
    
    var aspectRatio: CGFloat {
        guard height > 0 && width > 0 else { return 1.0 }
        let ratio = CGFloat(width) / CGFloat(height)
        guard ratio.isFinite && !ratio.isNaN && ratio > 0 else { return 1.0 }
        return ratio
    }
}

