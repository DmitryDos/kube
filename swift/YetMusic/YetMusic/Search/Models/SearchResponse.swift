import Foundation

enum SearchResultItem: Identifiable {
    case video(VideoResult)
    case author(AuthorResult)
    
    var id: String {
        switch self {
        case .video(let video): return "video_\(video.id)"
        case .author(let author): return "author_\(author.id)"
        }
    }
}

enum SearchFilter: String, CaseIterable, CustomStringConvertible {
    case all = "Всё"
    case authors = "Авторы"
    case videos = "Видео"
    
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
    let videos: [VideoResult]
}

struct AuthorResult: Codable {
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
}

struct VideoResult: Codable {
    let id: Int
    let title: String
    let description: String
    let userId: Int
    let fileSize: Int64
    let fileURL: String
    let thumbnailURL: String?
    let status: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, status
        case userId = "user_id"
        case fileSize = "file_size"
        case fileURL = "file_url"
        case thumbnailURL = "thumbnail_url"
        case createdAt = "created_at"
    }
    
    // Computed properties for compatibility with views
    var subtitle: String {
        return "Автор #\(userId)"
    }
    
    var imageURL: String? {
        return thumbnailURL ?? fileURL
    }
    
    var duration: TimeInterval {
        return 0 // Не доступно с сервера
    }
    
    var viewCount: Int {
        return 0 // Не доступно с сервера
    }
    
    var authorId: UUID {
        // Генерируем детерминированный UUID из userId
        var uuidString = "00000000-0000-0000-0000-"
        uuidString += String(format: "%012d", abs(userId))
        return UUID(uuidString: uuidString) ?? UUID()
    }
}

enum SearchResult: Codable {
    case video(VideoResult)
    case author(AuthorResult)
    
    private enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "video":
            let video = try container.decode(VideoResult.self, forKey: .data)
            self = .video(video)
        case "author":
            let author = try container.decode(AuthorResult.self, forKey: .data)
            self = .author(author)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type: \(type)")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .video(let video):
            try container.encode("video", forKey: .type)
            try container.encode(video, forKey: .data)
        case .author(let author):
            try container.encode("author", forKey: .type)
            try container.encode(author, forKey: .data)
        }
    }
    
    var item: SearchResultItem {
        switch self {
        case .video(let video): return .video(video)
        case .author(let author): return .author(author)
        }
    }
}
