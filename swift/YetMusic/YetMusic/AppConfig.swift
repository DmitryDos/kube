import Foundation

enum AppConfig {
    // Networking
    static let apiBaseURL: String = "https://conversational-zoila-flexuosely.ngrok-free.dev"
    static let authTokenKey: String = "authToken"
    static let requestTimeout: TimeInterval = 300
    static let resourceTimeout: TimeInterval = 600
    
    // Caching
    static let preloadedVideosMaxBytes: Int64 = 50 * 1024 * 1024
}


