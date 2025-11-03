import Foundation

enum AppConfig {
    // static let apiBaseURL: String = "https://conversational-zoila-flexuosely.ngrok-free.dev"
    static let apiBaseURL: String = "http://127.0.0.1:8080"
    static let authTokenKey: String = "authToken"
    static let requestTimeout: TimeInterval = 300
    static let resourceTimeout: TimeInterval = 600

    static let preloadedVideosMaxBytes: Int64 = 50 * 1024 * 1024
}


