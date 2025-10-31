import SwiftData
import Foundation

@Model
final class Track: Sendable {
    var id: UUID
    var title: String
    var artist: String
    var duration: TimeInterval
    var dateAdded: Date
    var remoteVideoId: Int?       // ID видео на сервере
    var videoURL: String?         // URL для стриминга с сервера
    var thumbnailURL: String?     // URL превью
    var isSaved: Bool             // Локально сохранено полностью
    var localFilePath: String?    // Путь к локальному файлу, если сохранен
    
    init(title: String, artist: String, duration: TimeInterval, remoteVideoId: Int? = nil, videoURL: String? = nil, thumbnailURL: String? = nil) {
        self.id = UUID()
        self.title = title
        self.artist = artist
        self.duration = duration
        self.dateAdded = Date()
        self.remoteVideoId = remoteVideoId
        self.videoURL = videoURL
        self.thumbnailURL = thumbnailURL
        self.isSaved = false
        self.localFilePath = nil
    }

    // URL для воспроизведения - приоритет отдаём серверу
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
    
    var isRemoteVideo: Bool {
        remoteVideoId != nil && videoURL != nil
    }
}
