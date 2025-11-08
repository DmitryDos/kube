//
//  VideoService.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 27.10.2025.
//

import Foundation
import UIKit

struct VideoResponse: Codable {
    let videos: [Track]
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
    
    private init() {}

    struct StreamURLResponse: Codable { let url: String }

    func fetchStreamURL(videoID: UUID) async throws -> URL {
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

    func deleteVideo(videoID: UUID) async throws {
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
    
    struct UpdateVideoResponse: Codable {
        let message: String
        let video: Track?
    }
    
    func updateVideoMetadata(videoID: UUID, title: String? = nil, description: String? = nil, thumbnail: UIImage? = nil) async throws -> Track? {
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
            
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw VideoError.invalidResponse
            }
            
            if let updateResponse = try? makeDecoder().decode(UpdateVideoResponse.self, from: data) {
                return updateResponse.video
            }
            return nil
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
            
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw VideoError.invalidResponse
            }
            
            if let updateResponse = try? makeDecoder().decode(UpdateVideoResponse.self, from: data) {
                return updateResponse.video
            }
            return nil
        }
    }
    
    private func getToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

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
