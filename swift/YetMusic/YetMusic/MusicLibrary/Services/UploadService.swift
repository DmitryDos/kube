import Foundation

final class UploadService {
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
        return URLSession(configuration: config)
    }()

    private func getToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }

    struct UploadResponse: Codable {
        let message: String
        let video: Video
    }

    func uploadVideo(fileURL: URL, title: String, description: String = "") async throws -> Video {
        guard let token = getToken() else {
            throw VideoError.unauthorized
        }

        guard var components = URLComponents(string: baseURL + "/api/videos/upload/raw") else {
            throw VideoError.invalidURL
        }
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "title", value: title)]
        if !description.isEmpty { queryItems.append(URLQueryItem(name: "description", value: description)) }
        components.queryItems = queryItems
        guard let url = components.url else { throw VideoError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 600

        let (data, response) = try await session.upload(for: request, fromFile: fileURL)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VideoError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            if let err = String(data: data, encoding: .utf8) { print("Server error response: \(err)") }
            throw VideoError.serverError(statusCode: httpResponse.statusCode)
        }

        let decoder = makeDecoder()
        let uploadResponse = try decoder.decode(UploadResponse.self, from: data)
        return uploadResponse.video
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

