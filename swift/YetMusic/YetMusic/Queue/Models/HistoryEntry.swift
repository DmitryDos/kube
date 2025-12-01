import SwiftData
import Foundation

@Model
final class HistoryEntry {
    var id: UUID
    var dayStart: Date
    var createdAt: Date
    // Убрали связь с Track - используем только trackId для независимости
    var trackId: UUID?
    var ownerId: UUID?
    var savedTitle: String
    var savedDesc: String
    var savedArtist: String  // Добавили для совместимости с savedArtist в CoreData
    var savedDuration: Double
    var savedThumbnailURL: String?

    init(dayStart: Date, track: Track) {
        self.id = UUID()
        self.dayStart = dayStart
        self.createdAt = Date()
        // НЕ устанавливаем track - только сохраняем данные
        self.trackId = track.id
        self.ownerId = track.ownerUserId
        self.savedTitle = track.title
        self.savedDesc = track.desc
        self.savedArtist = track.desc  // desc используется как artist
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

