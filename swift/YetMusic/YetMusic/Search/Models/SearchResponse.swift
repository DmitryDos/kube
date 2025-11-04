import Foundation

enum SearchResultItem: Identifiable {
    case video(VideoResult)
    case author(AuthorResult)
    
    var id: UUID {
        switch self {
        case .video(let video): return video.id
        case .author(let author): return author.id
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
    let id: UUID
    let title: String
    let subtitle: String
    let imageURL: String?
    let videoCount: Int
    let followerCount: Int
}

struct VideoResult: Codable {
    let id: UUID
    let title: String
    let subtitle: String
    let imageURL: String?
    let description: String
    let duration: TimeInterval
    let viewCount: Int
    let createdAt: Date
    let authorId: UUID
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
