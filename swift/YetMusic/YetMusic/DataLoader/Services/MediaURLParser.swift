import Foundation
import AVFoundation

class MediaURLParser {
    static let shared = MediaURLParser()
    
    private let session: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15"
        ]
        self.session = URLSession(configuration: configuration)
    }
    
    func parseMediaURL(_ url: URL) async throws -> (downloadURL: URL, title: String?, artist: String?) {
        // 1. Прямые медиа-ссылки (mp4, mp3 и т.д.)
        if isDirectMediaURL(url) {
            let metadata = try? await extractMetadata(from: url)
            return (url, metadata?.title, metadata?.artist)
        }
        
        // 2. YouTube (только информация)
        if isYouTubeURL(url) {
            return try await parseYouTube(url)
        }
        
        // 3. Универсальный парсинг для всех остальных сервисов
        return try await parseUniversalMediaURL(url)
    }
    
    // MARK: - Универсальный парсинг
    private func parseUniversalMediaURL(_ url: URL) async throws -> (URL, String?, String?) {
        // Получаем HTML страницы
        let (data, _) = try await session.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw MediaParserError.failedToParse
        }
        
        // Ищем медиафайлы в разных местах
        if let mediaURL = findMediaURLInHTML(html: html, baseURL: url) {
            let metadata = try? await extractMetadata(from: mediaURL)
            let pageMetadata = extractPageMetadata(html: html)
            
            return (
                mediaURL,
                pageMetadata.title ?? metadata?.title,
                pageMetadata.artist ?? metadata?.artist
            )
        }
        
        throw MediaParserError.noMediaFound
    }
    
    private func findMediaURLInHTML(html: String, baseURL: URL) -> URL? {
        let patterns = [
            // Open Graph видео
            #"<meta property="og:video" content="([^"]+)"#,
            #"<meta property="og:video:url" content="([^"]+)"#,
            #"<meta property="og:audio" content="([^"]+)"#,
            
            // Video tags
            #"<video[^>]*src="([^"]+)"#,
            #"<source[^>]*src="([^"]+)"#,
            
            // JSON данные с ссылками
            #""url":"([^"]+\.(mp4|mp3|m4a|webm))"#,
            #""video_url":"([^"]+)"#,
            #""src":"([^"]+\.(mp4|mp3|m4a|webm))"#,
            
            // Прямые ссылки в контенте
            #"https?://[^"\s]+\.(mp4|mp3|m4a|webm)[^"\s]*"#
        ]
        
        for pattern in patterns {
            if let match = html.firstMatch(pattern: pattern),
               let urlString = match.captures.first,
               let mediaURL = URL(string: urlString, relativeTo: baseURL) ?? URL(string: urlString) {
                return mediaURL
            }
        }
        
        return nil
    }
    
    private func extractPageMetadata(html: String) -> (title: String?, artist: String?) {
        var title: String?
        var artist: String?
        
        // Open Graph title
        if let ogTitle = html.firstMatch(pattern: #"<meta property="og:title" content="([^"]+)"#)?.captures.first {
            title = ogTitle
        }
        
        // Regular title
        else if let pageTitle = html.firstMatch(pattern: #"<title>([^<]+)</title>"#)?.captures.first {
            title = pageTitle
        }
        
        // Open Graph site name (часто используется как artist)
        if let siteName = html.firstMatch(pattern: #"<meta property="og:site_name" content="([^"]+)"#)?.captures.first {
            artist = siteName
        }
        
        return (title, artist)
    }
    
    // MARK: - Вспомогательные методы
    private func isDirectMediaURL(_ url: URL) -> Bool {
        let mediaExtensions = ["mp4", "mov", "m4v", "mp3", "m4a", "wav", "aac", "webm"]
        let pathExtension = url.pathExtension.lowercased()
        return !pathExtension.isEmpty && mediaExtensions.contains(pathExtension)
    }
    
    private func isYouTubeURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("youtube.com") || host.contains("youtu.be")
    }
    
    private func parseYouTube(_ url: URL) async throws -> (URL, String?, String?) {
        do {
            let (title, author) = try await getYouTubeInfo(url: url)
            return (url, title, author)
        } catch {
            let fallbackTitle = extractTitleFromURL(url)
            return (url, fallbackTitle, "YouTube")
        }
    }
    
    private func getYouTubeInfo(url: URL) async throws -> (title: String, author: String) {
        guard let oEmbedURL = URL(string: "https://www.youtube.com/oembed?url=\(url.absoluteString)&format=json") else {
            throw MediaParserError.invalidYouTubeURL
        }
        
        let (data, _) = try await session.data(from: oEmbedURL)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let title = json["title"] as? String,
              let author = json["author_name"] as? String else {
            throw MediaParserError.failedToParse
        }
        
        return (title, author)
    }
    
    private func extractTitleFromURL(_ url: URL) -> String {
        let lastPath = url.lastPathComponent
        if lastPath.isEmpty || lastPath == "/" {
            return "Video"
        }
        return url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }
    
    private func extractMetadata(from url: URL) async throws -> (title: String?, artist: String?) {
        let asset = AVAsset(url: url)
        let metadata = try await asset.load(.metadata)
        
        var title: String?
        var artist: String?
        
        for item in metadata {
            guard let commonKey = item.commonKey else { continue }
            
            switch commonKey {
            case .commonKeyTitle:
                title = item.stringValue
            case .commonKeyArtist:
                artist = item.stringValue
            default:
                break
            }
        }
        
        return (title, artist)
    }
}

// Расширение для работы с регулярками
extension String {
    func firstMatch(pattern: String) -> (match: String, captures: [String])? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)) else {
            return nil
        }
        
        let matchText = String(self[Range(match.range, in: self)!])
        var captures: [String] = []
        
        for i in 1..<match.numberOfRanges {
            if let range = Range(match.range(at: i), in: self) {
                captures.append(String(self[range]))
            }
        }
        
        return (matchText, captures)
    }
}

enum MediaParserError: LocalizedError {
    case unsupportedService
    case invalidYouTubeURL
    case failedToParse
    case noMediaFound
    
    var errorDescription: String? {
        switch self {
        case .unsupportedService:
            return "Данный сервис не поддерживается"
        case .invalidYouTubeURL:
            return "Неверная ссылка YouTube"
        case .failedToParse:
            return "Не удалось обработать ссылку"
        case .noMediaFound:
            return "Не удалось найти медиафайл на странице"
        }
    }
}
