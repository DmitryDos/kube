import SwiftData
import Foundation

final class PersistenceController {
    static let shared = PersistenceController()
    
    let container: ModelContainer
    let context: ModelContext
    
    private init() {
        do {
            let schema = Schema([Track.self, Playlist.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [configuration])
            context = ModelContext(container)
        } catch {
            print("❌ Failed to create persistent store, falling back to memory: \(error)")
            let schema = Schema([Track.self, Playlist.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: schema, configurations: [configuration])
            context = ModelContext(container)
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


