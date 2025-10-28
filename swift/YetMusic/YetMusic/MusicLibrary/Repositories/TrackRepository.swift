import SwiftData
import AVFoundation

class TrackRepository: ObservableObject {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    init() {
        do {
            self.modelContainer = try ModelContainer(for: Track.self)
            self.modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Failed to initialize SwiftData: \(error)")
        }
    }
    
    func getTracks(page: Int, pageSize: Int) -> [Track] {
            do {
                let offset = page * pageSize
                var descriptor = FetchDescriptor<Track>(
                    sortBy: [SortDescriptor(\.dateAdded)]
                )
                descriptor.fetchLimit = pageSize
                descriptor.fetchOffset = offset
                
                return try modelContext.fetch(descriptor)
            } catch {
                print("Error fetching paginated tracks: \(error)")
                return []
            }
        }
    
    func saveTrack(_ track: Track) {
        modelContext.insert(track)
        do {
            try modelContext.save()
        } catch {
            print("Error saving track: \(error)")
        }
    }
    
    func deleteTrack(_ track: Track) {
        modelContext.delete(track)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting track: \(error)")
        }
    }
    
    func updateTrackMetadata(track: Track) {
        do {
            try modelContext.save()
        } catch {
            print("Error updating track: \(error)")
        }
    }
}
