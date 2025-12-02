import SwiftData
import Foundation

// MARK: - Track Model
// Единая модель для всех случаев: сервер, клиент, SwiftData
@Model
final class Track: Sendable, Codable, Hashable {
    var id: UUID
    var title: String
    var desc: String
    var duration: TimeInterval
    var dateAdded: Date

    var videoURL: String?
    var thumbnailURL: String?
    var ownerUserId: UUID?
    var fileSize: Int64?
    var status: String?
    var contentType: String?
    var isPrivate: Bool

    var isSaved: Bool
    var localFilePath: String?

    init(id: UUID, title: String, desc: String, duration: TimeInterval, videoURL: String? = nil, thumbnailURL: String? = nil, ownerUserId: UUID? = nil, dateAdded: Date = Date(), isPrivate: Bool = false, contentType: String? = nil) {
        self.id = id
        self.title = title
        self.desc = desc
        self.duration = duration
        self.dateAdded = dateAdded
        self.videoURL = videoURL
        self.thumbnailURL = thumbnailURL
        self.ownerUserId = ownerUserId
        self.fileSize = nil
        self.status = nil
        self.contentType = contentType
        self.isPrivate = isPrivate
        self.isSaved = false
        self.localFilePath = nil
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description  // -> artist
        case userId = "user_id"
        case fileSize = "file_size"
        case fileURL = "file_url"
        case thumbnailURL = "thumbnail_url"
        case imageURL = "image_url" // Для обратной совместимости со старым форматом
        case status
        case createdAt = "created_at"
        case duration
        case contentType = "content_type"
        case isPrivate = "is_private"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(UUID.self, forKey: .id)
        // title и description могут быть пустыми для фото
        self.title = (try? container.decode(String.self, forKey: .title)) ?? ""
        self.desc = (try? container.decode(String.self, forKey: .description)) ?? ""
        self.duration = (try? container.decode(TimeInterval.self, forKey: .duration)) ?? 0
        self.dateAdded = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        
        self.videoURL = try? container.decode(String.self, forKey: .fileURL)
        // Пробуем сначала thumbnail_url, потом image_url для обратной совместимости
        if let thumbnailURL = try? container.decode(String.self, forKey: .thumbnailURL), !thumbnailURL.isEmpty {
            self.thumbnailURL = thumbnailURL
        } else if let imageURL = try? container.decode(String.self, forKey: .imageURL), !imageURL.isEmpty {
            self.thumbnailURL = imageURL
        } else {
            self.thumbnailURL = nil
        }
        self.ownerUserId = try? container.decode(UUID.self, forKey: .userId)
        self.fileSize = try? container.decode(Int64.self, forKey: .fileSize)
        self.status = try? container.decode(String.self, forKey: .status)
        self.contentType = try? container.decode(String.self, forKey: .contentType)
        self.isPrivate = (try? container.decode(Bool.self, forKey: .isPrivate)) ?? false

        self.isSaved = false
        self.localFilePath = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(desc, forKey: .description)
        try container.encode(duration, forKey: .duration)
        try container.encode(dateAdded, forKey: .createdAt)
        
        if let userId = ownerUserId {
            try container.encode(userId, forKey: .userId)
        }
        if let size = fileSize {
            try container.encode(size, forKey: .fileSize)
        }
        if let url = videoURL {
            try container.encode(url, forKey: .fileURL)
        }
        if let thumb = thumbnailURL {
            try container.encode(thumb, forKey: .thumbnailURL)
        }
        if let status = status {
            try container.encode(status, forKey: .status)
        }
        if let contentType = contentType {
            try container.encode(contentType, forKey: .contentType)
        }
    }

    var playableURL: URL? {
        if isSaved, let path = localFilePath {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) { return url }
        }
        if let videoURL = videoURL, let url = URL(string: videoURL) {
            return url
        }
        return nil
    }

    var imageURL: URL? {
        let baseURL = VideoService.shared.baseURL
        let isPhoto = contentType == "image"
        
        // Для фото всегда используем /api/photos/{id}
        if isPhoto {
            return URL(string: baseURL + "/api/photos/\(id.uuidString)")
        }
        
        // Для остального используем thumbnailURL
        guard let thumbnailURLString = thumbnailURL, !thumbnailURLString.isEmpty else {
            // Fallback на ID трека для видео/музыки
            return URL(string: baseURL + "/api/videos/\(id.uuidString)/thumbnail")
        }
        
        // Если URL относительный (начинается с /), добавляем baseURL
        if thumbnailURLString.hasPrefix("/") {
            return URL(string: baseURL + thumbnailURLString)
        }
        // Если это UUID без префикса, используем endpoint для видео
        else if let uuid = UUID(uuidString: thumbnailURLString) {
            return URL(string: baseURL + "/api/videos/\(uuid.uuidString)/thumbnail")
        }
        // Если это полный URL (http:// или https://), используем как есть
        else if thumbnailURLString.hasPrefix("http://") || thumbnailURLString.hasPrefix("https://") {
            return URL(string: thumbnailURLString)
        }
        // Иначе считаем относительным путем
        else {
            return URL(string: baseURL + "/" + thumbnailURLString)
        }
    }

    static func == (lhs: Track, rhs: Track) -> Bool {
        return lhs.id == rhs.id
    }
        
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
