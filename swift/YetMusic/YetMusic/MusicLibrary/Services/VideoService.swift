//
//  VideoService.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 27.10.2025.
//

import Foundation
import UIKit

struct Video: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let userId: Int
    let fileSize: Int64
    let fileURL: String
    let thumbnailURL: String?
    let status: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, description
        case userId = "user_id"
        case fileSize = "file_size"
        case fileURL = "file_url"
        case thumbnailURL = "thumbnail_url"
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
    
    let baseURL = AppConfig.apiBaseURL
    private let tokenKey = AppConfig.authTokenKey
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfig.requestTimeout
        config.timeoutIntervalForResource = AppConfig.resourceTimeout
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

    struct StreamURLResponse: Codable { let url: String }

    func fetchStreamURL(videoID: Int) async throws -> URL {
        guard let token = getToken() else { throw VideoError.unauthorized }
        guard let url = URL(string: baseURL + "/api/videos/\(videoID)/stream/url") else { throw VideoError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw VideoError.invalidResponse
        }
        let decoded = try makeDecoder().decode(StreamURLResponse.self, from: data)
        guard let finalURL = URL(string: decoded.url) else { throw VideoError.invalidURL }
        return finalURL
    }

    func deleteVideo(videoID: Int) async throws {
        guard let token = getToken() else { throw VideoError.unauthorized }
        guard let url = URL(string: baseURL + "/api/videos/\(videoID)") else { throw VideoError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw VideoError.invalidResponse
        }
    }
    
    func updateVideoMetadata(videoID: Int, title: String? = nil, description: String? = nil, thumbnail: UIImage? = nil) async throws {
        guard let token = getToken() else { throw VideoError.unauthorized }
        guard let url = URL(string: baseURL + "/api/videos/\(videoID)") else { throw VideoError.invalidURL }
        
        if let thumbnail = thumbnail {
            guard let imageData = thumbnail.jpegData(compressionQuality: 0.8) else {
                throw VideoError.invalidData
            }
            
            let boundary = UUID().uuidString
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            
            if let title = title {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"title\"\r\n\r\n")
                body.append(title)
                body.append("\r\n")
            }
            
            if let description = description {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"description\"\r\n\r\n")
                body.append(description)
                body.append("\r\n")
            }
            
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"thumbnail\"; filename=\"thumbnail.jpg\"\r\n")
            body.append("Content-Type: image/jpeg\r\n\r\n")
            body.append(imageData)
            body.append("\r\n")
            body.append("--\(boundary)--\r\n")
            
            request.httpBody = body
            
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw VideoError.invalidResponse
            }
        } else {
            struct UpdateRequest: Codable {
                let title: String?
                let description: String?
            }
            
            let updateRequest = UpdateRequest(title: title, description: description)
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(updateRequest)
            
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw VideoError.invalidResponse
            }
        }
    }
    
    private func getToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func loadVideos(page: Int = 0, pageSize: Int = 20, query: String? = nil, userId: Int? = nil, mine: Bool = false, completion: @escaping ([Video]) -> Void) {
        guard let token = getToken() else {
            completion([])
            return
        }
        
        var params = ["page=\(page)", "limit=\(pageSize)"]
        if let q = query, !q.isEmpty, let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            params.append("q=\(encoded)")
        }
        if mine {
            params.append("mine=true")
        } else if let userId = userId {
            params.append("user_id=\(userId)")
        }
        let endpoint = "/api/videos/all?" + params.joined(separator: "&")

        makeRequest(
            endpoint: endpoint,
            method: "GET",
            token: token
        ) { (result: Result<VideoResponse, Error>) in
            switch result {
            case .success(let response):
                print("[VideoService] Loaded videos count: \(response.videos.count)")
                completion(response.videos)
            case .failure:
                print("[VideoService] Failed to load videos")
                completion([])
            }
        }
    }
    
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
                if let data = data, let raw = String(data: data, encoding: .utf8) {
                    print("[VideoService] Server error (\(httpResponse.statusCode)): \n\(raw)")
                }
                let statusError = VideoError.serverError(statusCode: httpResponse.statusCode)
                completion(.failure(statusError))
                return
            }
            
            guard let data = data else {
                completion(.failure(VideoError.noData))
                return
            }
            
            do {
                let decoder = makeDecoder()
                let decodedResponse = try decoder.decode(T.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                if let raw = String(data: data, encoding: .utf8) {
                    print("[VideoService] Decode error: \(error)\nRaw: \n\(raw)")
                }
                completion(.failure(error))
            }
        }.resume()
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

// MARK: - Decoder helper
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
