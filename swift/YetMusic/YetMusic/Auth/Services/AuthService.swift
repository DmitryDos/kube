import Foundation
import SwiftUI

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Environment(\.isLandscape) private var isLandscape
    
    private let baseURL = AppConfig.apiBaseURL
    private let tokenKey = AppConfig.authTokenKey
    private let userKey = "currentUser"
    
    private init() {
        restoreSession()
    }
    
    // MARK: - Session Management
    
    private func restoreSession() {
        guard let token = getToken(),
              let userData = UserDefaults.standard.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return
        }
        
        // Проверяем токен на сервере
        validateToken(token) { isValid in
            DispatchQueue.main.async {
                if isValid {
                    self.currentUser = user
                    self.isAuthenticated = true
                    print("Сессия восстановлена")
                } else {
                    self.clearSession()
                }
            }
        }
    }
    
    private func saveSession(user: User, token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
        UserDefaults.standard.synchronize()
    }
    
    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        UserDefaults.standard.synchronize()
    }
    
    private func getToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
    
    // MARK: - API Methods
    
    func login(email: String, password: String) {
        errorMessage = nil
        
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Заполните все поля"
            return
        }
        
        let loginRequest = LoginRequest(email: email, password: password)
        
        makeRequest(
            endpoint: "/api/auth/login",
            method: "POST",
            body: loginRequest
        ) { (result: Result<AuthResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.isAuthenticated = true
                    self.currentUser = response.user
                    self.saveSession(user: response.user, token: response.token)
                    print("Успешный вход: \(response.user.email)")
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func register(email: String, password: String, name: String) {
        errorMessage = nil
        
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            errorMessage = "Заполните все поля"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Пароль должен содержать минимум 6 символов"
            return
        }
        
        let registerRequest = RegisterRequest(email: email, password: password, name: name)
        
        makeRequest(
            endpoint: "/api/auth/register",
            method: "POST",
            body: registerRequest
        ) { (result: Result<AuthResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.isAuthenticated = true
                    self.currentUser = response.user
                    self.saveSession(user: response.user, token: response.token)
                    print("Успешная регистрация: \(response.user.email)")
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func logout() {
        if let token = getToken() {
            // Отправляем запрос на логаут для blacklist токена
            makeRequest(
                endpoint: "/api/auth/logout",
                method: "POST",
                token: token
            ) { (result: Result<[String: String], Error>) in
                // Логаут в любом случае, даже если запрос не удался
                DispatchQueue.main.async {
                    self.performLogout()
                }
            }
        } else {
            performLogout()
        }
    }
    
    private func performLogout() {
        isAuthenticated = false
        currentUser = nil
        errorMessage = nil
        clearSession()
        print("Пользователь вышел из системы")
    }
    
    private func validateToken(_ token: String, completion: @escaping (Bool) -> Void) {
        makeRequest(
            endpoint: "/api/auth/profile",
            method: "GET",
            token: token
        ) { (result: Result<[String: User], Error>) in
            switch result {
            case .success:
                completion(true)
            case .failure:
                completion(false)
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
            completion(.failure(NetworkError.invalidURL))
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
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let statusError = NetworkError.serverError(statusCode: httpResponse.statusCode)
                completion(.failure(statusError))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                // Настройка декодера для дат (ISO8601)
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
                let decodedResponse = try decoder.decode(T.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                // Логируем ошибку декодирования для диагностики
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[AuthService] Decode error: \(error)")
                    print("[AuthService] Response data: \(jsonString)")
                    print("[AuthService] Expected type: \(T.self)")
                }
                completion(.failure(error))
            }
        }.resume()
    }
}

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .serverError(let statusCode):
            return "Ошибка сервера: \(statusCode)"
        case .noData:
            return "Нет данных"
        }
    }
}
