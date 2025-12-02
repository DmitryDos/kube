import Foundation
import UIKit

final class UploadService: NSObject {
    static let shared = UploadService()

    private let baseURL = AppConfig.apiBaseURL
    private let tokenKey = AppConfig.authTokenKey

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 600
        config.timeoutIntervalForResource = 3600
        if #available(iOS 13.0, *) {
            config.allowsExpensiveNetworkAccess = true
            config.allowsConstrainedNetworkAccess = true
            config.waitsForConnectivity = true
        }
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private var uploadTasks: [Int: (continuation: Any, fileName: String, responseData: Data, type: UploadType)] = [:]
    
    func updateMusicMetadata(musicID: UUID, title: String?, artist: String?, cover: UIImage?) async throws {
        // Используем VideoService для обновления метаданных
        try await VideoService.shared.updateVideoMetadata(
            videoID: musicID,
            title: title,
            description: artist,
            thumbnail: cover
        )
    }
    
    func updatePhotoMetadata(photoID: UUID, title: String?, description: String?) async throws {
        guard let token = getToken() else {
            throw VideoError.unauthorized
        }

        guard let url = URL(string: baseURL + "/api/photos/\(photoID.uuidString)") else {
            throw VideoError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        var body: [String: Any?] = [:]
        if let title = title {
            body["title"] = title
        }
        if let description = description {
            body["description"] = description
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VideoError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw VideoError.serverError(statusCode: httpResponse.statusCode)
        }
    }
    
    enum UploadType {
        case video
        case audio
        case photo
    }

    private func getToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }

    struct UploadResponse: Codable {
        let message: String
        let video: Track?
        let music: Track? // Музыка теперь тоже Track с content_type
        let photo: Track? // Фото теперь тоже Track с content_type = "image"
    }

    func uploadVideo(fileURL: URL) async throws -> Track {
        guard let token = getToken() else {
            throw VideoError.unauthorized
        }

        guard let url = URL(string: baseURL + "/api/videos/upload") else {
            throw VideoError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 600

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"video\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)

        let videoData = try Data(contentsOf: fileURL)
        body.append(videoData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        // Используем uploadTask с Data для получения данных ответа
        // Для больших файлов это может быть проблемой, но необходимо для получения ответа
        return try await withCheckedThrowingContinuation { continuation in
            let fileName = fileURL.lastPathComponent
            
            // Создаем uploadTask с Data
            let task = session.uploadTask(with: request, from: body)
            
            // Регистрируем задачу для отслеживания прогресса
            uploadTasks[task.taskIdentifier] = (continuation: continuation, fileName: fileName, responseData: Data(), type: .video)
            VideoTransferService.shared.registerUpload(task: task, fileURL: fileURL, title: fileName)
            
            task.resume()
        }
    }
    
    func uploadAudio(fileURL: URL) async throws -> Track {
        guard let token = getToken() else {
            throw VideoError.unauthorized
        }

        guard let url = URL(string: baseURL + "/api/music/upload") else {
            throw VideoError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 600

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!)

        let audioData = try Data(contentsOf: fileURL)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return try await withCheckedThrowingContinuation { continuation in
            let fileName = fileURL.lastPathComponent
            
            let task = session.uploadTask(with: request, from: body)
            
            uploadTasks[task.taskIdentifier] = (continuation: continuation, fileName: fileName, responseData: Data(), type: .audio)
            VideoTransferService.shared.registerUpload(task: task, fileURL: fileURL, title: fileName)
            
            task.resume()
        }
    }
    
    func uploadPhoto(fileURL: URL) async throws -> Track {
        guard let token = getToken() else {
            throw VideoError.unauthorized
        }

        guard let url = URL(string: baseURL + "/api/photos/upload") else {
            throw VideoError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 600

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)

        let imageData = try Data(contentsOf: fileURL)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return try await withCheckedThrowingContinuation { continuation in
            let fileName = fileURL.lastPathComponent
            
            let task = session.uploadTask(with: request, from: body)
            
            uploadTasks[task.taskIdentifier] = (continuation: continuation, fileName: fileName, responseData: Data(), type: .photo)
            VideoTransferService.shared.registerUpload(task: task, fileURL: fileURL, title: fileName)
            
            task.resume()
        }
    }
    
}

extension UploadService: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        VideoTransferService.shared.updateProgress(task: task, sent: totalBytesSent, expected: totalBytesExpectedToSend)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard var taskInfo = uploadTasks.removeValue(forKey: task.taskIdentifier) else {
            return
        }

        if let error = error {
            VideoTransferService.shared.finish(task: task, error: error)
            resumeContinuation(taskInfo: taskInfo, error: error)
            return
        }

        guard let httpResponse = task.response as? HTTPURLResponse else {
            let responseError = VideoError.invalidResponse
            VideoTransferService.shared.finish(task: task, error: responseError)
            resumeContinuation(taskInfo: taskInfo, error: responseError)
            return
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let serverError = VideoError.serverError(statusCode: httpResponse.statusCode)
            VideoTransferService.shared.finish(task: task, error: serverError)
            resumeContinuation(taskInfo: taskInfo, error: serverError)
            return
        }

        if taskInfo.responseData.isEmpty {
            let responseError = VideoError.invalidResponse
            VideoTransferService.shared.finish(task: task, error: responseError)
            resumeContinuation(taskInfo: taskInfo, error: responseError)
        } else {
            do {
                let decoder = makeDecoder()
                // Логируем ответ для диагностики
                if let jsonString = String(data: taskInfo.responseData, encoding: .utf8) {
                    print("[UploadService] Response JSON: \(jsonString)")
                }
                let uploadResponse = try decoder.decode(UploadResponse.self, from: taskInfo.responseData)
                VideoTransferService.shared.finish(task: task, error: nil)
                resumeContinuation(taskInfo: taskInfo, response: uploadResponse, type: taskInfo.type)
            } catch {
                print("[UploadService] Decoding error: \(error)")
                if let jsonString = String(data: taskInfo.responseData, encoding: .utf8) {
                    print("[UploadService] Failed to decode JSON: \(jsonString)")
                }
                VideoTransferService.shared.finish(task: task, error: error)
                resumeContinuation(taskInfo: taskInfo, error: error)
            }
        }
    }
    
    private func resumeContinuation(taskInfo: (continuation: Any, fileName: String, responseData: Data, type: UploadType), response: UploadResponse? = nil, type: UploadType? = nil, error: Error? = nil) {
        if let error = error {
            switch taskInfo.type {
            case .video:
                if let continuation = taskInfo.continuation as? CheckedContinuation<Track, Error> {
                    continuation.resume(throwing: error)
                }
            case .audio:
                if let continuation = taskInfo.continuation as? CheckedContinuation<Music, Error> {
                    continuation.resume(throwing: error)
                }
            case .photo:
                if let continuation = taskInfo.continuation as? CheckedContinuation<Track, Error> {
                    continuation.resume(throwing: error)
                }
            }
            return
        }
        
        guard let response = response, let type = type else {
            let responseError = VideoError.invalidResponse
            resumeContinuation(taskInfo: taskInfo, error: responseError)
            return
        }
        
        switch type {
        case .video:
            if let continuation = taskInfo.continuation as? CheckedContinuation<Track, Error> {
                if let video = response.video {
                    continuation.resume(returning: video)
                } else {
                    continuation.resume(throwing: VideoError.invalidResponse)
                }
            }
        case .audio:
            if let continuation = taskInfo.continuation as? CheckedContinuation<Track, Error> {
                if let music = response.music {
                    continuation.resume(returning: music)
                } else {
                    continuation.resume(throwing: VideoError.invalidResponse)
                }
            }
        case .photo:
            if let continuation = taskInfo.continuation as? CheckedContinuation<Track, Error> {
                if let track = response.photo {
                    print("[UploadService] Photo upload response - ID: \(track.id), fileURL: \(track.videoURL ?? "nil")")
                    continuation.resume(returning: track)
                } else {
                    print("[UploadService] Photo upload failed - response.photo is nil")
                    continuation.resume(throwing: VideoError.invalidResponse)
                }
            }
        }
    }
}

extension UploadService: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Накапливаем данные ответа
        if var taskInfo = uploadTasks[dataTask.taskIdentifier] {
            taskInfo.responseData.append(data)
            uploadTasks[dataTask.taskIdentifier] = taskInfo
        }
    }
}

// Reuse same tolerant date decoder as VideoService
private func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        let fmt1 = ISO8601DateFormatter()
        fmt1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = fmt1.date(from: dateString) { return d }
        let fmt2 = ISO8601DateFormatter()
        fmt2.formatOptions = [.withInternetDateTime]
        if let d = fmt2.date(from: dateString) { return d }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateString)")
    }
    return decoder
}
