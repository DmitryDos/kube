import Foundation
import Combine

enum TrackState {
    case none
    case played
    case current
    case upcoming
}

class QueueService: ObservableObject {
    static let shared = QueueService()
    
    @Published var currentQueue: [Track] = []       // храним сами треки, а не fileName
    @Published var wishlistQueue: [Track] = []      // храним сами треки
    @Published var currentIndex: Int = -1
    @Published var isLooping: Bool = false
    
    private let trackController = TrackController.shared
    
    private init() {}
    
    // MARK: - Основные методы
    
    func getRandomTrack() -> Track? {
        return trackController.getRandomTrack()
    }
    
    func playTrack(_ track: Track) {
        // Убираем из wishlist
        wishlistQueue.removeAll { $0.id == track.id }

        // Проверяем есть ли в currentQueue
        if let index = currentQueue.firstIndex(where: { $0.id == track.id }) {
            currentIndex = index
        } else {
            currentQueue.append(track)
            currentIndex = currentQueue.count - 1
        }

        AudioPlayerService.shared.load(track: track)
        AudioPlayerService.shared.play()
    }
    
    func playRandomIfEmpty() {
        if getCurrentTrack() == nil, let randomTrack = getRandomTrack() {
            playTrack(randomTrack)
        }
    }
    
    func addToWishlist(_ track: Track) {
        if !wishlistQueue.contains(where: { $0.id == track.id }) &&
           !currentQueue.contains(where: { $0.id == track.id }) {
            wishlistQueue.append(track)
        }
    }
    
    func getCurrentTrack() -> Track? {
        if 0 <= currentIndex && currentIndex < currentQueue.count {
            return currentQueue[currentIndex]
        }
        return nil
    }
    
    func getNextTrack() -> Track? {
        if isLooping, let currentTrack = getCurrentTrack() {
            return currentTrack
        }

        // Следующий в currentQueue
        if currentIndex + 1 < currentQueue.count {
            return currentQueue[currentIndex + 1]
        }

        // Берем из wishlist
        if !wishlistQueue.isEmpty {
            let nextTrack = wishlistQueue.removeFirst()
            currentQueue.append(nextTrack)
            return nextTrack
        }

        // Случайный трек
        if let randomTrack = getRandomTrack() {
            currentQueue.append(randomTrack)
            return randomTrack
        }
        
        return nil
    }
    
    func getPreviousTrack() -> Track? {
        guard currentIndex > 0 else { return nil }
        return currentQueue[currentIndex - 1]
    }
    
    func moveToNext() -> Track? {
        if let nextTrack = getNextTrack() {
            if !isLooping {
                currentIndex += 1
            }
            return nextTrack
        }
        return nil
    }
    
    func moveToPrevious() -> Track? {
        if let prevTrack = getPreviousTrack() {
            currentIndex -= 1
            return prevTrack
        }
        return nil
    }
    
    func toggleLoop() {
        isLooping.toggle()
    }
    
    func clearCurrentQueue() {
        currentQueue.removeAll()
        currentIndex = 0
    }
    
    func clearWishlist() {
        wishlistQueue.removeAll()
    }

    func removeTrackFromQueues(_ track: Track) {
        currentQueue.removeAll { $0.id == track.id }
        wishlistQueue.removeAll { $0.id == track.id }

        if currentIndex >= currentQueue.count {
            currentIndex = max(0, currentQueue.count - 1)
        }
    }

    func moveToCurrentPosition(_ track: Track) {
        // Убираем трек из всех очередей
        currentQueue.removeAll { $0.id == track.id }
        wishlistQueue.removeAll { $0.id == track.id }
        
        // Вставляем на текущую позицию
        currentQueue.insert(track, at: currentIndex)
    }
        
    func moveAfterCurrent(_ track: Track) {
        currentQueue.removeAll { $0.id == track.id }
        wishlistQueue.removeAll { $0.id == track.id }

        let insertIndex = currentIndex + 1
        if insertIndex <= currentQueue.count {
            currentQueue.insert(track, at: insertIndex)
        } else {
            currentQueue.append(track)
        }
    }

    func movePlayedToUpcoming(_ track: Track) {
        currentQueue.removeAll { $0.id == track.id }
        wishlistQueue.removeAll { $0.id == track.id }
        
        // Уменьшаем индекс если удалили трек перед текущим
        if let removedIndex = currentQueue.firstIndex(where: { $0.id == track.id }),
           removedIndex < currentIndex {
            currentIndex -= 1
        }

        wishlistQueue.insert(track, at: 0)
    }

    func getAllQueueTracks() -> [Track] {
        return currentQueue + wishlistQueue
    }
        
    func getTrackState(_ track: Track) -> TrackState {
        let isInCurrentQueue = currentQueue.contains(where: { $0.id == track.id })
        let isInWishlist = wishlistQueue.contains(where: { $0.id == track.id })

        guard isInCurrentQueue || isInWishlist else {
            return .none
        }
        
        guard let currentTrack = getCurrentTrack() else {
            return .upcoming
        }
        
        if track.id == currentTrack.id {
            return .current
        }

        // Находим индекс трека в currentQueue
        if let trackIndex = currentQueue.firstIndex(where: { $0.id == track.id }),
           trackIndex < currentIndex {
            return .played
        }
        
        return .upcoming
    }
        
    // Этот метод больше не нужен, но оставляем для совместимости
    func getTrack(byFileName fileName: String) -> Track? {
        // Ищем по ID или другим полям, если нужно
        return trackController.tracks.first { $0.id.uuidString == fileName }
    }
    
    func getCurrentQueueCount() -> Int {
        return currentQueue.count
    }
    
    func getWishlistQueueCount() -> Int {
        return wishlistQueue.count
    }
    
    // Новый метод для поиска трека по ID
    func getTrack(byId trackId: UUID) -> Track? {
        return trackController.tracks.first { $0.id == trackId }
    }
}
