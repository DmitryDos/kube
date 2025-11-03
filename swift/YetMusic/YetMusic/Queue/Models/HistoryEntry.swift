import SwiftData
import Foundation

@Model
final class HistoryEntry {
    var id: UUID
    var dayStart: Date
    var createdAt: Date
    var track: Track?
    var trackId: UUID?
    // Snapshot metadata to keep history stable even if Track is deleted
    var savedTitle: String
    var savedArtist: String
    var savedDuration: Double
    var savedThumbnailURL: String?

    init(dayStart: Date, track: Track) {
        self.id = UUID()
        self.dayStart = dayStart
        self.createdAt = Date()
        self.track = track
        self.trackId = track.id
        self.savedTitle = track.title
        self.savedArtist = track.artist
        self.savedDuration = track.duration
        self.savedThumbnailURL = track.thumbnailURL
    }
}

extension Date {
    var startOfDayUTC: Date {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar.startOfDay(for: self)
    }
}

