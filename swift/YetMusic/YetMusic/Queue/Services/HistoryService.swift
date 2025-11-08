import SwiftData
import Foundation

final class HistoryService: ObservableObject {
    static let shared = HistoryService()

    @Published private(set) var lastUpdate: Date = Date()

    private let persistence = PersistenceController.shared
    private var context: ModelContext { persistence.context }

    private init() {}

    struct HistoryItem: Identifiable {
        let id: UUID
        let dayStart: Date
        let createdAt: Date
        let title: String
        let desc: String
        let duration: Double
        let thumbnailURL: String?
        let track: Track? // resolved if exists
    }

    func recordPlayed(_ track: Track, at date: Date = Date()) {
        let day = date.startOfDayUTC

        // Fetch by day only to keep predicate simple; filter in memory by id
        let dayDescriptor = FetchDescriptor<HistoryEntry>(
            predicate: #Predicate { entry in
                entry.dayStart == day
            },
            sortBy: [SortDescriptor(\HistoryEntry.createdAt, order: .forward)]
        )

        if let existing = try? context.fetch(dayDescriptor) {
            let exists = existing.contains { entry in
                return entry.trackId == track.id
            }
            if exists { return }
        }

        // Создаем entry без связи с Track - только сохраняем данные
        let entry = HistoryEntry(dayStart: day, track: track)
        context.insert(entry)
        persistence.saveIfNeeded()
        DispatchQueue.main.async { self.lastUpdate = Date() }
    }

    func availableDays() -> [Date] {
        let descriptor = FetchDescriptor<HistoryEntry>(
            sortBy: [SortDescriptor(\HistoryEntry.dayStart, order: .reverse)]
        )
        guard let entries = try? context.fetch(descriptor) else { return [] }
        let unique = Set(entries.map { $0.dayStart })
        return unique.sorted(by: { $0 > $1 })
    }

    func items(for day: Date) -> [HistoryItem] {
        let dayStart = day.startOfDayUTC
        let descriptor = FetchDescriptor<HistoryEntry>(
            predicate: #Predicate { entry in
                entry.dayStart == dayStart
            },
            sortBy: [SortDescriptor(\HistoryEntry.createdAt, order: .forward)]
        )
        guard let entries = try? context.fetch(descriptor) else { return [] }
        return entries.map { entry in
            return HistoryItem(
                id: entry.id,
                dayStart: entry.dayStart,
                createdAt: entry.createdAt,
                title: entry.savedTitle,
                desc: entry.savedDesc,
                duration: entry.savedDuration,
                thumbnailURL: entry.savedThumbnailURL,
                track: nil
            )
        }
    }

    func title(for day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "Сегодня" }
        if cal.isDateInYesterday(day) { return "Вчера" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        return formatter.string(from: day)
    }
}
