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
    
    init(title: String, artist: String, duration: TimeInterval, remoteVideoId: Int? = nil, videoURL: String? = nil, thumbnailURL: String? = nil) {
        self.id = UUID()
        self.title = title
        self.artist = artist
        self.duration = duration
        self.dateAdded = Date()
        self.remoteVideoId = remoteVideoId
        self.videoURL = videoURL
        self.thumbnailURL = thumbnailURL
    }

    // URL для воспроизведения - приоритет отдаём серверу
    var playableURL: URL? {
        if let videoURL = videoURL, let url = URL(string: videoURL) {
            return url
        }
        return nil
    }
    
    var isRemoteVideo: Bool {
        remoteVideoId != nil && videoURL != nil
    }
}
