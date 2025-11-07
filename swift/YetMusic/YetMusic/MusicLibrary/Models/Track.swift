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

    var isSaved: Bool
    var localFilePath: String?

    init(id: UUID, title: String, desc: String, duration: TimeInterval, videoURL: String? = nil, thumbnailURL: String? = nil, ownerUserId: UUID? = nil, dateAdded: Date = Date()) {
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
        case status
        case createdAt = "created_at"
        case duration
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.desc = try container.decode(String.self, forKey: .description)
        self.duration = (try? container.decode(TimeInterval.self, forKey: .duration)) ?? 0
        self.dateAdded = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        
        self.videoURL = try? container.decode(String.self, forKey: .fileURL)
        self.thumbnailURL = try? container.decode(String.self, forKey: .thumbnailURL)
        self.ownerUserId = try? container.decode(UUID.self, forKey: .userId)
        self.fileSize = try? container.decode(Int64.self, forKey: .fileSize)
        self.status = try? container.decode(String.self, forKey: .status)

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

    static func == (lhs: Track, rhs: Track) -> Bool {
        return lhs.id == rhs.id
    }
        
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
