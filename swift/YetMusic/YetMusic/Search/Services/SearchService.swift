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
    
    func search(query: String, filter: SearchFilter = .all, loadMore: Bool = false) {
        guard !query.isEmpty else {
            loadPopularVideos()
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
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] results in
                if loadMore {
                    self?.searchResults.append(contentsOf: results)
                } else {
                    self?.searchResults = results
                }
                self?.hasMoreResults = results.count >= 20
            }
            .store(in: &cancellables)
    }
    
    func loadPopularVideos() {
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
                    self?.fallbackLoadPopularVideos()
                }
            } receiveValue: { [weak self] results in
                self?.searchResults = results
                self?.hasMoreResults = false
            }
            .store(in: &cancellables)
    }
    
    private func fallbackLoadPopularVideos() {
        var urlComponents = URLComponents(string: "\(baseURL)/api/videos/all")
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: "0"),
            URLQueryItem(name: "limit", value: "20")
        ]
        
        guard let url = urlComponents?.url else { return }
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: VideosResponse.self, decoder: jsonDecoder)
            .map { response in
                response.videos.map { SearchResultItem.video($0) }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
            } receiveValue: { [weak self] results in
                self?.searchResults = results
                self?.hasMoreResults = false
            }
            .store(in: &cancellables)
    }
    
    func loadMoreResults() {
        guard !currentQuery.isEmpty, hasMoreResults, !isLoading else { return }
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
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
