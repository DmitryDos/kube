import Foundation

class TrackCache {
    static let shared = TrackCache()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let cacheInfoFile: URL
    
    private var accessHistory: [String: Date] = [:]
    private var currentCacheSize: Int = 0
    private let queue = DispatchQueue(label: "com.yourapp.trackcache", attributes: .concurrent) // Добавляем очередь для синхронизации
    
    private init() {
        self.cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("tracks")
        self.cacheInfoFile = cacheDirectory.appendingPathComponent("cache_info.json")
        
        loadCacheInfo()
    }
    
    func saveFile(_ data: Data, fileName: String) throws -> URL {
        return try queue.sync(flags: .barrier) { // Барьер для записи
            let fileURL = cacheDirectory.appendingPathComponent(fileName)

            if !fileManager.fileExists(atPath: cacheDirectory.path) {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            }

            if fileManager.fileExists(atPath: fileURL.path) {
                try? fileManager.removeItem(at: fileURL)
                if let oldDate = accessHistory[fileName] {
                    try? removeFile(fileName: fileName)
                }
            }

            try data.write(to: fileURL)

            accessHistory[fileName] = Date()
            currentCacheSize += data.count

            saveCacheInfo()
            
            return fileURL
        }
    }
    
    func getFileURL(fileName: String) -> URL? {
        return queue.sync {
            let fileURL = cacheDirectory.appendingPathComponent(fileName)
            guard fileManager.fileExists(atPath: fileURL.path) else { return nil }

            queue.async(flags: .barrier) {
                self.accessHistory[fileName] = Date()
                self.saveCacheInfo()
            }
            
            return fileURL
        }
    }
    
    func removeFile(fileName: String) throws {
        try queue.sync(flags: .barrier) {
            let fileURL = cacheDirectory.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: fileURL.path) {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                let fileSize = attributes[.size] as? Int ?? 0
                
                try fileManager.removeItem(at: fileURL)
                accessHistory.removeValue(forKey: fileName)
                currentCacheSize = max(0, currentCacheSize - fileSize)
                saveCacheInfo()
            }
        }
    }
    
    func clearCache() throws {
        try queue.sync(flags: .barrier) {
            if fileManager.fileExists(atPath: cacheDirectory.path) {
                try fileManager.removeItem(at: cacheDirectory)
            }
            accessHistory.removeAll()
            currentCacheSize = 0
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            saveCacheInfo()
        }
    }

    private func saveCacheInfo() {
        do {
            let cacheInfo = CacheInfo(accessHistory: accessHistory, currentSize: currentCacheSize)
            let data = try JSONEncoder().encode(cacheInfo)
            try data.write(to: cacheInfoFile)
        } catch {
            print("Ошибка при сохранении информации о кэше: \(error)")
        }
    }
    
    private func loadCacheInfo() {
        guard fileManager.fileExists(atPath: cacheInfoFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: cacheInfoFile)
            let cacheInfo = try JSONDecoder().decode(CacheInfo.self, from: data)

            var validHistory: [String: Date] = [:]
            var validSize = 0
            
            for (fileName, date) in cacheInfo.accessHistory {
                let fileURL = cacheDirectory.appendingPathComponent(fileName)
                if fileManager.fileExists(atPath: fileURL.path) {
                    validHistory[fileName] = date
                    let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                    validSize += attributes[.size] as? Int ?? 0
                }
            }
            
            self.accessHistory = validHistory
            self.currentCacheSize = validSize

            saveCacheInfo()
            
        } catch {
            print("Ошибка при загрузке информации о кэше: \(error)")
        }
    }
}

struct CacheInfo: Codable {
    let accessHistory: [String: Date]
    let currentSize: Int
}
