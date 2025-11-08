import Foundation

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

    private var uploadTasks: [Int: (continuation: CheckedContinuation<Track, Error>, fileName: String, responseData: Data)] = [:]

    private func getToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }

    struct UploadResponse: Codable {
        let message: String
        let video: Track
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
            uploadTasks[task.taskIdentifier] = (continuation: continuation, fileName: fileName, responseData: Data())
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
            taskInfo.continuation.resume(throwing: error)
            return
        }

        guard let httpResponse = task.response as? HTTPURLResponse else {
            let responseError = VideoError.invalidResponse
            VideoTransferService.shared.finish(task: task, error: responseError)
            taskInfo.continuation.resume(throwing: responseError)
            return
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let serverError = VideoError.serverError(statusCode: httpResponse.statusCode)
            VideoTransferService.shared.finish(task: task, error: serverError)
            taskInfo.continuation.resume(throwing: serverError)
            return
        }

        // Данные должны быть получены через URLSessionDataDelegate.didReceive
        // Если данных нет, значит ответ пустой
        if taskInfo.responseData.isEmpty {
            let responseError = VideoError.invalidResponse
            VideoTransferService.shared.finish(task: task, error: responseError)
            taskInfo.continuation.resume(throwing: responseError)
        } else {
            // Данные получены, декодируем их
            do {
                let decoder = makeDecoder()
                let uploadResponse = try decoder.decode(UploadResponse.self, from: taskInfo.responseData)
                VideoTransferService.shared.finish(task: task, error: nil)
                taskInfo.continuation.resume(returning: uploadResponse.video)
            } catch {
                VideoTransferService.shared.finish(task: task, error: error)
                taskInfo.continuation.resume(throwing: error)
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
