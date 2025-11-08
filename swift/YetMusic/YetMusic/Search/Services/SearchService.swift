import Foundation
import Combine

class SearchService: ObservableObject {
    static let shared = SearchService()
    
    @Published var searchResults: [SearchResultItem] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var hasMoreResults = true
    
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = AppConfig.apiBaseURL
    private var currentPage = 1
    private var currentQuery = ""
    private var currentFilter: SearchFilter = .all
    private var hasLoadedInitialVideos = false
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: config)
    }()
    
    func search(query: String, filter: SearchFilter = .all, loadMore: Bool = false) {
        guard !query.isEmpty else {
            loadPopularVideos(force: true)
            return
        }
        
        if !loadMore {
            currentPage = 1
            currentQuery = query
            currentFilter = filter
            searchResults = []
            hasMoreResults = true
        } else {
            currentPage += 1
        }
        
        isLoading = true
        error = nil
        
        var urlComponents = URLComponents(string: "\(baseURL)/api/search")
        urlComponents?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: "\(currentPage)"),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "filter", value: filter.rawValue.lowercased())
        ]
        
        guard let url = urlComponents?.url else { 
            print("[SearchService] ❌ ERROR: Failed to create URL")
            isLoading = false
            return 
        }
        
        print("[SearchService] 📤 REQUEST (search):")
        print("  URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: AppConfig.authTokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("  Authorization: Bearer \(token.prefix(20))...")
        } else {
            print("  Authorization: none")
        }
        print("  Method: GET")
        print("  Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        session.dataTaskPublisher(for: request)
            .handleEvents(
                receiveOutput: { data, response in
                    print("[SearchService] 📥 RESPONSE (search):")
                    if let httpResponse = response as? HTTPURLResponse {
                        print("  Status: \(httpResponse.statusCode)")
                        print("  Headers: \(httpResponse.allHeaderFields)")
                    }
                    if let dataString = String(data: data, encoding: .utf8) {
                        let preview = dataString.prefix(500)
                        print("  Body preview (first 500 chars): \(preview)")
                        if dataString.hasPrefix("<") {
                            print("  ⚠️ WARNING: Response is HTML, not JSON!")
                        }
                    }
                    print("  Data size: \(data.count) bytes")
                }
            )
            .map(\.data)
            .decode(type: SearchResponse.self, decoder: jsonDecoder)
            .map { response in
                response.results.map { $0.item }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("[SearchService] Search error: \(error)")
                    if let decodingError = error as? DecodingError {
                        print("[SearchService] Decoding error details: \(decodingError)")
                    }
                    if let urlError = error as? URLError {
                        print("[SearchService] URL error: \(urlError)")
                    }
                    self?.error = "Ошибка загрузки результатов: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] results in
                print("[SearchService] Received \(results.count) results")
                if loadMore {
                    self?.searchResults.append(contentsOf: results)
                } else {
                    self?.searchResults = results
                }
                self?.hasMoreResults = results.count >= 20
                self?.error = nil
            }
            .store(in: &cancellables)
    }
    
    func loadPopularVideos(force: Bool = false) {
        searchResults = []
        
        isLoading = true
        currentQuery = ""
        currentFilter = .all
        currentPage = 1
        
        var urlComponents = URLComponents(string: "\(baseURL)/api/search")
        urlComponents?.queryItems = [
            URLQueryItem(name: "q", value: ""),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "limit", value: "20")
        ]
        
        guard let url = urlComponents?.url else { 
            print("[SearchService] ❌ ERROR: Failed to create URL")
            isLoading = false
            return 
        }
        
        print("[SearchService] 📤 REQUEST:")
        print("  URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: AppConfig.authTokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("  Authorization: Bearer \(token.prefix(20))...")
        } else {
            print("  Authorization: none")
        }
        print("  Method: GET")
        print("  Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .handleEvents(
                receiveOutput: { data, response in
                    print("[SearchService] 📥 RESPONSE:")
                    if let httpResponse = response as? HTTPURLResponse {
                        print("  Status: \(httpResponse.statusCode)")
                        print("  Headers: \(httpResponse.allHeaderFields)")
                    }
                    if let dataString = String(data: data, encoding: .utf8) {
                        let preview = dataString.prefix(500)
                        print("  Body preview (first 500 chars): \(preview)")
                        if dataString.hasPrefix("<") {
                            print("  ⚠️ WARNING: Response is HTML, not JSON!")
                        }
                    }
                    print("  Data size: \(data.count) bytes")
                }
            )
            .map(\.data)
            .decode(type: SearchResponse.self, decoder: jsonDecoder)
            .map { response in
                response.results.map { $0.item }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("[SearchService] Load popular videos error: \(error)")
                    if let decodingError = error as? DecodingError {
                        print("[SearchService] Decoding error details: \(decodingError)")
                    }
                    if let urlError = error as? URLError {
                        print("[SearchService] URL error: \(urlError)")
                    }
                    self?.error = "Ошибка загрузки: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] results in
                print("[SearchService] Loaded \(results.count) popular videos")
                self?.searchResults = results
                self?.hasMoreResults = false
                self?.error = nil
                self?.hasLoadedInitialVideos = true
            }
            .store(in: &cancellables)
    }
    
    func loadMoreResults() {
        guard !currentQuery.isEmpty, hasMoreResults, !isLoading else { return }
        print("[SearchService] Loading more results for query: \(currentQuery), page: \(currentPage + 1)")
        search(query: currentQuery, filter: currentFilter, loadMore: true)
    }
    
    func searchWithPagination(
        query: String?,
        filter: SearchFilter = .videos,
        page: Int,
        pageSize: Int = 20,
        userId: UUID? = nil,
        mine: Bool = false,
        trackIds: [UUID]? = nil,
        completion: @escaping (Int, [Track], Bool) -> Void
    ) {
        var urlComponents = URLComponents(string: "\(baseURL)/api/search")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(pageSize)"),
            URLQueryItem(name: "filter", value: filter.rawValue.lowercased())
        ]
        
        if let q = query, !q.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: q))
        }
        
        if mine {
            queryItems.append(URLQueryItem(name: "mine", value: "true"))
        } else if let userId = userId {
            queryItems.append(URLQueryItem(name: "user_id", value: userId.uuidString))
        }
        
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            completion(page, [], false)
            return
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: AppConfig.authTokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: SearchResponse.self, decoder: jsonDecoder)
            .map { response -> (Int, [Track], Bool) in
                let tracks = response.results.compactMap { result -> Track? in
                    guard case .video(let track) = result else { return nil }
                    if let trackIds = trackIds {
                        return trackIds.contains(track.id) ? track : nil
                    }
                    return track
                }
                let hasMore = tracks.count >= pageSize
                return (page, tracks, hasMore)
            }
            .receive(on: DispatchQueue.main)
            .sink { result in
                if case .failure = result {
                    completion(page, [], false)
                }
            } receiveValue: { page, tracks, hasMore in
                completion(page, tracks, hasMore)
            }
            .store(in: &cancellables)
    }
    
    func clearResults() {
        searchResults = []
        error = nil
        currentPage = 1
        currentQuery = ""
        hasMoreResults = true
        hasLoadedInitialVideos = false
        
        URLCache.shared.removeAllCachedResponses()
    }
    
    static func clearAllCaches() {
        URLCache.shared.removeAllCachedResponses()
        
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        SearchService.shared.clearResults()
    }
    
    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss.SZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss.SSSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss.SS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss.S'Z'",
                "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss'Z'",
                "yyyy-MM-dd'T'HH:mmZZZZZ",
                "yyyy-MM-dd'T'HH:mm'Z'"
            ]
            
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            let isoFormatter1 = ISO8601DateFormatter()
            isoFormatter1.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
            if let date = isoFormatter1.date(from: dateString) {
                return date
            }
            
            let isoFormatter2 = ISO8601DateFormatter()
            isoFormatter2.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter2.date(from: dateString) {
                return date
            }
            
            let isoFormatter3 = ISO8601DateFormatter()
            isoFormatter3.formatOptions = [.withInternetDateTime, .withTimeZone]
            if let date = isoFormatter3.date(from: dateString) {
                return date
            }
            
            let isoFormatter4 = ISO8601DateFormatter()
            isoFormatter4.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter4.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
        }
        return decoder
    }
}
