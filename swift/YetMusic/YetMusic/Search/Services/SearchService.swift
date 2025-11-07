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
        
        guard let url = urlComponents?.url else { return }
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTaskPublisher(for: request)
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
        // Загружаем только один раз при первом вызове, если не принудительно
        if hasLoadedInitialVideos && !force {
            return
        }
        
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
        
        guard let url = urlComponents?.url else { return }
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTaskPublisher(for: request)
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
        // Загружаем больше результатов только если есть активный поисковый запрос
        // Для популярных видео пагинация не нужна
        guard !currentQuery.isEmpty, hasMoreResults, !isLoading else { return }
        print("[SearchService] Loading more results for query: \(currentQuery), page: \(currentPage + 1)")
        search(query: currentQuery, filter: currentFilter, loadMore: true)
    }
    
    func clearResults() {
        searchResults = []
        error = nil
        currentPage = 1
        currentQuery = ""
        hasMoreResults = true
    }
    
    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Пробуем разные форматы ISO8601/RFC3339
            let formats = [
                // ISO8601 с дробными секундами и часовым поясом
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss.SZZZZZ",
                // ISO8601 с дробными секундами UTC
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss.SSSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss.SS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss.S'Z'",
                // ISO8601 с часовым поясом
                "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss'Z'",
                // ISO8601 без секунд
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
            
            // Пробуем ISO8601DateFormatter с различными опциями
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
