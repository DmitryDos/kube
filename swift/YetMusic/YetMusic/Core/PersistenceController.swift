import SwiftData
import Foundation

final class PersistenceController {
    static let shared = PersistenceController()
    
    let container: ModelContainer
    let context: ModelContext
    
    private init() {
        do {
            let schema = Schema([Track.self, Playlist.self, HistoryEntry.self])
            // Используем версионирование схемы для миграции
            // При изменении схемы создается новая база с версией
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let url = documentsPath.appendingPathComponent("Model_v2.store")
            let configuration = ModelConfiguration(
                schema: schema,
                url: url,
                cloudKitDatabase: .none
            )
            container = try ModelContainer(for: schema, configurations: [configuration])
            context = ModelContext(container)
            print("✅ SwiftData store created successfully")
        } catch {
            print("❌ Failed to create persistent store: \(error)")
            // Если миграция не удалась, удаляем старую базу и создаем новую
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let url = documentsPath.appendingPathComponent("Model_v2.store")
            try? FileManager.default.removeItem(at: url)
            // Также удаляем старую базу без версии
            let oldURL = documentsPath.appendingPathComponent("default.store")
            try? FileManager.default.removeItem(at: oldURL)
            
            // Создаем новую базу в памяти для продолжения работы
            let schema = Schema([Track.self, Playlist.self, HistoryEntry.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: schema, configurations: [configuration])
            context = ModelContext(container)
            print("⚠️ Using in-memory store (previous data was incompatible)")
        }
    }
    
    func saveIfNeeded() {
        do {
            try context.save()
        } catch {
            print("❌ SwiftData save error: \(error)")
        }
    }
}


