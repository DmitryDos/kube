import Foundation
import Combine

final class BackgroundUploadService: NSObject {
    static let shared = BackgroundUploadService()

    private let baseURL = "https://conversational-zoila-flexuosely.ngrok-free.dev"
    private let tokenKey = "authToken"
    private let sessionIdentifier = "com.yetmusic.upload.background"

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        if #available(iOS 13.0, *) {
            config.allowsExpensiveNetworkAccess = true
            config.allowsConstrainedNetworkAccess = true
        }
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    // Called by AppDelegate when system finishes background events for this session
    var backgroundCompletionHandler: (() -> Void)?

    private func getToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }

    func enqueueUpload(fileURL: URL, title: String, description: String = "") {
        guard let token = getToken() else { return }

        guard var components = URLComponents(string: baseURL + "/api/videos/upload/raw") else { return }
        var items = [URLQueryItem(name: "title", value: title)]
        if !description.isEmpty { items.append(URLQueryItem(name: "description", value: description)) }
        components.queryItems = items
        guard let url = components.url else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(contentType(for: fileURL), forHTTPHeaderField: "Content-Type")

        let task = session.uploadTask(with: request, fromFile: fileURL)

        VideoTransferService.shared.registerUpload(task: task, fileURL: fileURL, title: title)
        task.resume()
    }

    private func contentType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "mkv": return "video/x-matroska"
        case "m4v": return "video/x-m4v"
        default: return "application/octet-stream"
        }
    }
}

extension BackgroundUploadService: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        VideoTransferService.shared.updateProgress(task: task, sent: totalBytesSent, expected: totalBytesExpectedToSend)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        VideoTransferService.shared.finish(task: task, error: error)
        if error == nil {
            if let http = task.response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                DispatchQueue.main.async {
                    // Обновляем плейлисты/очередь метаданными после успешной загрузки
                    TrackController.shared.loadFirstPage()
                }
            }
        }
    }
}

extension BackgroundUploadService: URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if let handler = backgroundCompletionHandler {
            DispatchQueue.main.async { handler() }
            backgroundCompletionHandler = nil
        }
    }
}


