//
//  VideoService.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 27.10.2025.
//

import Foundation

struct Video: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let fileSize: Int64
    let fileURL: String
    let status: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, description
        case fileSize = "file_size"
        case fileURL = "file_url"
        case status
        case createdAt = "created_at"
    }
}

struct VideoResponse: Codable {
    let videos: [Video]
}

struct CreateVideoRequest: Codable {
    let title: String
    let description: String
}

class VideoService: ObservableObject {
    static let shared = VideoService()
    
    private let baseURL = "https://conversational-zoila-flexuosely.ngrok-free.dev"
    private let tokenKey = "authToken"
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 600
        if #available(iOS 13.0, *) {
            config.allowsExpensiveNetworkAccess = true
            config.allowsConstrainedNetworkAccess = true
            config.waitsForConnectivity = true
        }
        return URLSession(configuration: config)
    }()
    
    @Published var videos: [Video] = []
    
    private init() {
        // Убираем loadVideos() из init, т.к. теперь требуется пагинация
    }
    
    private func getToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
    
    // MARK: - API Methods
    
    func uploadVideo(videoData: Data, title: String, description: String = "") async throws -> Video {
        guard let token = getToken() else {
            throw VideoError.unauthorized
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "\(baseURL)/api/videos/upload")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300
        
        let httpBody = createMultipartBody(
            videoData: videoData,
            title: title,
            description: description,
            boundary: boundary
        )
        request.httpBody = httpBody
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VideoError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("Server error response: \(errorData)")
            }
            throw VideoError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        struct UploadResponse: Codable {
            let message: String
            let video: Video
        }
        
        let uploadResponse = try decoder.decode(UploadResponse.self, from: data)
        
        await MainActor.run {
            videos.append(uploadResponse.video)
        }
        
        return uploadResponse.video
    }
    
    func loadVideos(page: Int = 0, pageSize: Int = 20, completion: @escaping ([Video]) -> Void) {
        guard let token = getToken() else {
            completion([])
            return
        }
        
        makeRequest(
            endpoint: "/api/videos/?page=\(page)&limit=\(pageSize)",
            method: "GET",
            token: token
        ) { (result: Result<VideoResponse, Error>) in
            switch result {
            case .success(let response):
                completion(response.videos)
            case .failure:
                completion([])
            }
        }
    }
    
    // MARK: - Network Helper
    
    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: String,
        body: Encodable? = nil,
        token: String? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(VideoError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                completion(.failure(error))
                return
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(VideoError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let statusError = VideoError.serverError(statusCode: httpResponse.statusCode)
                completion(.failure(statusError))
                return
            }
            
            guard let data = data else {
                completion(.failure(VideoError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let decodedResponse = try decoder.decode(T.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func createMultipartBody(videoData: Data, title: String, description: String, boundary: String) -> Data {
        var body = Data()
        
        // Добавляем title
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"title\"\r\n\r\n")
        body.append("\(title)\r\n")
        
        // Добавляем description
        if !description.isEmpty {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"description\"\r\n\r\n")
            body.append("\(description)\r\n")
        }
        
        // Добавляем видео файл
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"video\"; filename=\"video.mp4\"\r\n")
        body.append("Content-Type: video/mp4\r\n\r\n")
        body.append(videoData)
        body.append("\r\n")
        
        // Завершаем boundary
        body.append("--\(boundary)--\r\n")
        
        return body
    }
}

enum VideoError: LocalizedError {
    case unauthorized
    case invalidResponse
    case serverError(statusCode: Int)
    case invalidData
    case invalidURL
    case noData
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Не авторизован"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .serverError(let statusCode):
            return "Ошибка сервера: \(statusCode)"
        case .invalidData:
            return "Неверные данные"
        case .invalidURL:
            return "Неверный URL"
        case .noData:
            return "Нет данных"
        }
    }
}

// MARK: - Data Extensions
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
