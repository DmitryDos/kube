import SwiftData
import AVFoundation

class TrackRepository: ObservableObject {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    init() {
        self.modelContainer = PersistenceController.shared.container
        self.modelContext = PersistenceController.shared.context
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
