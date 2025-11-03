import Foundation

final class PreloadService {
    static let shared = PreloadService()
    
    private let ioQueue = DispatchQueue(label: "PreloadService.io")
    private let session: URLSession
    private let repository = TrackRepository()
    
    private let maxCacheBytes: Int64 = AppConfig.preloadedVideosMaxBytes
    private var inProgress: Set<UUID> = []
    
    private init() {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.allowsExpensiveNetworkAccess = true
        session = URLSession(configuration: config)
    }
    
    func startPreloading(for track: Track) {
        guard !track.isSaved, let videoId = track.remoteVideoId else { return }
        guard !inProgress.contains(track.id) else { return }
        inProgress.insert(track.id)
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            do {
                let streamURL = try await VideoService.shared.fetchStreamURL(videoID: videoId)
                try await self.downloadAndStore(url: streamURL, for: track)
            } catch {

            }
            self.inProgress.remove(track.id)
        }
    }
    
    private func downloadAndStore(url: URL, for track: Track) async throws {
        let (tmpURL, response) = try await session.download(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return }
        
        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: tmpURL.path)
        let size = (attributes[.size] as? NSNumber)?.int64Value ?? 0
        guard size > 0 else { return }
        
        // If single file exceeds cache cap, skip
        guard size <= maxCacheBytes else {
            try? FileManager.default.removeItem(at: tmpURL)
            return
        }
        
        let storageDir = try ensureStorageDirectory()
        try evictIfNeeded(forAdditionalSize: size, in: storageDir)
        
        let destURL = storageDir.appendingPathComponent("track-\(track.id.uuidString).mp4")
        // Replace existing
        try? FileManager.default.removeItem(at: destURL)
        try FileManager.default.moveItem(at: tmpURL, to: destURL)
        
        // Persist metadata
        DispatchQueue.main.async {
            track.isSaved = true
            track.localFilePath = destURL.path
            self.repository.updateTrackMetadata(track: track)
            TrackController.shared.objectWillChange.send()
        }
    }
    
    private func ensureStorageDirectory() throws -> URL {
        let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = base.appendingPathComponent("YetMusic/PreloadedVideos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        // Exclude from iCloud backups
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableDir = dir
        try? mutableDir.setResourceValues(values)
        // One-time migration from old Caches path
        migrateFromOldCacheIfNeeded(into: dir)
        return dir
    }

    private func migrateFromOldCacheIfNeeded(into newDir: URL) {
        let fm = FileManager.default
        guard let caches = try? fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else { return }
        let oldDir = caches.appendingPathComponent("YetMusic/PreloadedVideos", isDirectory: true)
        guard fm.fileExists(atPath: oldDir.path) else { return }
        guard let items = try? fm.contentsOfDirectory(at: oldDir, includingPropertiesForKeys: nil) else { return }
        for url in items {
            let dest = newDir.appendingPathComponent(url.lastPathComponent)
            if !fm.fileExists(atPath: dest.path) {
                try? fm.moveItem(at: url, to: dest)
            }
        }
        try? fm.removeItem(at: oldDir)
    }
    
    private func evictIfNeeded(forAdditionalSize size: Int64, in directory: URL) throws {
        var entries: [(url: URL, size: Int64, mod: Date)] = []
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.contentModificationDateKey, .fileSizeKey, .isDirectoryKey]
        let urls = try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys)
        var total: Int64 = 0
        for url in urls {
            let r = try url.resourceValues(forKeys: Set(keys))
            if r.isDirectory == true { continue }
            let s = Int64(r.fileSize ?? 0)
            let m = r.contentModificationDate ?? Date.distantPast
            entries.append((url, s, m))
            total += s
        }
        if total + size <= maxCacheBytes { return }
        // Evict LRU
        let sorted = entries.sorted { $0.mod < $1.mod }
        var currentTotal = total
        for item in sorted {
            try? fm.removeItem(at: item.url)
            currentTotal -= item.size
            if currentTotal + size <= maxCacheBytes { break }
        }
    }
}


