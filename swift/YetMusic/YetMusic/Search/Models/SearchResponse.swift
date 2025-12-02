import Foundation

enum SearchResultItem: Identifiable {
    case video(Track)
    case author(AuthorResult)
    
    var id: String {
        switch self {
        case .video(let track): return "video_\(track.id)"
        case .author(let author): return "author_\(author.id)"
        }
    }

    static func == (lhs: SearchResultItem, rhs: SearchResultItem) -> Bool {
        return lhs.id == rhs.id
    }
        
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum SearchFilter: String, CaseIterable, CustomStringConvertible {
    case all = "Всё"
    case authors = "Авторы"
    case videos = "Видео"
    case music = "Музыка"
    case photos = "Фото"
    
    var description: String {
        return self.rawValue
    }
}

struct SearchResponse: Codable {
    let results: [SearchResult]
    let pagination: PaginationInfo
}

struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
}

struct VideosResponse: Codable {
    let videos: [Track]
}

struct AuthorResult: Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: String?
    let videoCount: Int
    let followerCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, title, subtitle
        case imageURL = "imageURL"
        case videoCount = "videoCount"
        case followerCount = "followerCount"
    }
    
    // Computed property для совместимости с UUID
    var uuid: UUID {
        // Если строка уже валидный UUID, возвращаем его
        if let uuid = UUID(uuidString: id) {
            return uuid
        }
        // Иначе генерируем детерминированный UUID из строки
        var uuidString = "00000000-0000-0000-0000-"
        let numericId = id.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if let num = Int(numericId) {
            uuidString += String(format: "%012d", abs(num))
        } else {
            // Fallback: используем хеш строки
            uuidString += String(format: "%012d", abs(id.hashValue))
        }
        return UUID(uuidString: uuidString) ?? UUID()
    }
    
    static func == (lhs: AuthorResult, rhs: AuthorResult) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum SearchResult: Codable {
    case video(Track)
    case author(AuthorResult)
    
    private enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "video":
            let track = try container.decode(Track.self, forKey: .data)
            self = .video(track)
        case "author":
            let author = try container.decode(AuthorResult.self, forKey: .data)
            self = .author(author)
        case "music", "photo":
            // Бэкенд возвращает VideoResponse (Track) для музыки и фото, просто декодируем как Track
            let track = try container.decode(Track.self, forKey: .data)
            self = .video(track)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type: \(type)")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .video(let track):
            // Определяем тип по contentType
            let contentType = track.contentType?.lowercased() ?? ""
            let type: String
            if contentType == "audio" {
                type = "music"
            } else if contentType == "image" {
                type = "photo"
            } else {
                type = "video"
            }
            try container.encode(type, forKey: .type)
            try container.encode(track, forKey: .data)
        case .author(let author):
            try container.encode("author", forKey: .type)
            try container.encode(author, forKey: .data)
        }
    }
    
    var item: SearchResultItem {
        switch self {
        case .video(let track): return .video(track)
        case .author(let author): return .author(author)
        }
    }
}
