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
    
    @Published var currentQueue: [Track] = []
    @Published var wishlistQueue: [Track] = []
    @Published var currentIndex: Int = -1
    @Published var isLooping: Bool = false
    
    private let trackController = TrackController.shared
    private let historyService = HistoryService.shared
    
    private init() {}
    
    // MARK: - Основные методы

    // MARK: - Валидация ссылок на модели
    private func purgeInvalid() {
        let validIds = Set(trackController.tracks.map { $0.id })
        if !validIds.isEmpty {
            currentQueue.removeAll { !validIds.contains($0.id) }
            wishlistQueue.removeAll { !validIds.contains($0.id) }
            if currentIndex >= currentQueue.count { currentIndex = max(-1, currentQueue.count - 1) }
        }
    }

    private func resolve(_ track: Track) -> Track {
        if let live = trackController.tracks.first(where: { $0.id == track.id }) { return live }
        return track
    }
    
    func getRandomTrack() -> Track? {
        return trackController.getRandomTrack()
    }
    
    func playTrack(_ track: Track) {
        purgeInvalid()
        let track = resolve(track)
        wishlistQueue.removeAll { $0.id == track.id }

        if let current = getCurrentTrack(), current.id == track.id {
            AudioPlayerService.shared.play()
            return
        }

        historyService.recordPlayed(track)

        if currentIndex > 0 {
            let start = max(0, currentIndex - 5)
            let end = max(0, currentIndex - 1)

            if let dupIndex = currentQueue[start...end].firstIndex(where: { $0.id == track.id }) {
                currentQueue.remove(at: dupIndex)
            }
        }

        currentQueue.append(track)
        currentIndex = currentQueue.count - 1

        AudioPlayerService.shared.load(track: track)
        AudioPlayerService.shared.play()
    }
    
    func playRandomIfEmpty() {
        if getCurrentTrack() == nil, let randomTrack = getRandomTrack() {
            playTrack(randomTrack)
        }
    }
    
    func addToWishlist(_ track: Track) {
        purgeInvalid()
        let track = resolve(track)
        if !wishlistQueue.contains(where: { $0.id == track.id }) {
            wishlistQueue.append(track)
        }
    }
    
    func getCurrentTrack() -> Track? {
        purgeInvalid()
        if 0 <= currentIndex && currentIndex < currentQueue.count { return currentQueue[currentIndex] }
        return nil
    }

    func playNextTrack() {
        if isLooping, let currentTrack = getCurrentTrack() {
            playFromStack(index: currentIndex)
        }

        if currentIndex + 1 < currentQueue.count {
            playFromStack(index: currentIndex + 1)
        }

        if !wishlistQueue.isEmpty {
            let nextTrack = wishlistQueue.removeFirst()
            playTrack(nextTrack)
        }

        if let randomTrack = getRandomTrack() {
            playTrack(randomTrack)
        }
    }

    func playPreviousTrack() -> Track? {
        guard currentIndex > 0 else { return nil }
        return currentQueue[currentIndex - 1]
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

    func clearCurrentSelectionAfterFinish() {
        currentIndex = -1
    }

    func playFromStack(index: Int) {
        guard 0 <= index && index < currentQueue.count else { return }
        currentIndex = index
        let track = currentQueue[index]
        AudioPlayerService.shared.load(track: track)
        AudioPlayerService.shared.play()
    }

    func removeTrackFromQueues(_ track: Track) {
        wishlistQueue.removeAll { $0.id == track.id }
    }

    func getTrack(byId trackId: UUID) -> Track? {
        return trackController.tracks.first { $0.id == trackId }
    }
}
