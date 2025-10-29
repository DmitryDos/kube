import Foundation

final class UploadService {
    static let shared = UploadService()

    private let baseURL = "https://conversational-zoila-flexuosely.ngrok-free.dev"
    private let tokenKey = "authToken"

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

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let uploadResponse = try decoder.decode(UploadResponse.self, from: data)
        return uploadResponse.video
    }
}


