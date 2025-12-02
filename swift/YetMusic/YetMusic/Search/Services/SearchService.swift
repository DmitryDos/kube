import Foundation
import Combine

class SearchService: ObservableObject {
    static let shared = SearchService()
    
    // Отдельные хранилища для каждого типа
    @Published var videoResults: [Track] = []
    @Published var musicResults: [Track] = [] // Все как Track
    @Published var photoResults: [Track] = []
    @Published var authorResults: [AuthorResult] = []
    
    // Отдельные курсоры пагинации для каждого типа
    private var videoPage: [String: Int] = [:] // query -> page
    private var musicPage: [String: Int] = [:]
    private var photoPage: [String: Int] = [:]
    private var authorPage: [String: Int] = [:]
    
    // Флаги "есть ещё" для каждого типа
    private var videoHasMore: [String: Bool] = [:]
    private var musicHasMore: [String: Bool] = [:]
    private var photoHasMore: [String: Bool] = [:]
    private var authorHasMore: [String: Bool] = [:]
    
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = AppConfig.apiBaseURL
    private var currentQuery = ""
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: config)
    }()
    
    // Computed property для объединённых результатов (для вкладки "всё")
    // Объединяет все результаты и сортирует по дате (сверху новое)
    var allResults: [SearchResultItem] {
        var results: [SearchResultItem] = []
        
        // Добавляем все видео
        results.append(contentsOf: videoResults.map { .video($0) })
        
        // Добавляем всю музыку
        results.append(contentsOf: musicResults.map { .video($0) })
        
        // Добавляем все фото
        results.append(contentsOf: photoResults.map { .video($0) })
        
        // Добавляем всех авторов
        results.append(contentsOf: authorResults.map { .author($0) })
        
        // Сортируем по дате (сверху новое)
        // Для авторов используем текущую дату, так как у них нет dateAdded
        return results.sorted { item1, item2 in
            let date1: Date
            let date2: Date
            
            switch item1 {
            case .video(let track):
                date1 = track.dateAdded
            case .author:
                date1 = Date() // Авторы всегда в конце
            }
            
            switch item2 {
            case .video(let track):
                date2 = track.dateAdded
            case .author:
                date2 = Date() // Авторы всегда в конце
            }
            
            return date1 > date2
        }
    }
    
    func search(query: String, filter: SearchFilter = .all) {
        currentQuery = query
        currentFilter = filter
        
        // Загружаем все типы параллельно
        if filter == .all {
            searchVideos(query: query, loadMore: false)
            searchMusic(query: query, loadMore: false)
            searchPhotos(query: query, loadMore: false)
            searchAuthors(query: query, loadMore: false)
        } else {
            // Загружаем только выбранный тип
            switch filter {
            case .videos:
                searchVideos(query: query, loadMore: false)
            case .music:
                searchMusic(query: query, loadMore: false)
            case .photos:
                searchPhotos(query: query, loadMore: false)
            case .authors:
                searchAuthors(query: query, loadMore: false)
            case .all:
                break
            }
        }
    }
    
    func loadMore(filter: SearchFilter) {
        switch filter {
        case .videos:
            if videoHasMore[currentQuery] == true {
                searchVideos(query: currentQuery, loadMore: true)
            }
        case .music:
            if musicHasMore[currentQuery] == true {
                searchMusic(query: currentQuery, loadMore: true)
            }
        case .photos:
            if photoHasMore[currentQuery] == true {
                searchPhotos(query: currentQuery, loadMore: true)
            }
        case .authors:
            if authorHasMore[currentQuery] == true {
                searchAuthors(query: currentQuery, loadMore: true)
            }
        case .all:
            // Загружаем больше для всех типов
            if videoHasMore[currentQuery] == true {
                searchVideos(query: currentQuery, loadMore: true)
            }
            if musicHasMore[currentQuery] == true {
                searchMusic(query: currentQuery, loadMore: true)
            }
            if photoHasMore[currentQuery] == true {
                searchPhotos(query: currentQuery, loadMore: true)
            }
            if authorHasMore[currentQuery] == true {
                searchAuthors(query: currentQuery, loadMore: true)
            }
        }
    }
    
    func searchVideos(query: String, loadMore: Bool) {
        if !loadMore {
            videoResults = []
            videoPage[query] = 1
            videoHasMore[query] = true
        }
        
        guard let page = videoPage[query], videoHasMore[query] == true else { return }
        
        var urlComponents = URLComponents(string: "\(baseURL)/api/search")
        urlComponents?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "filter", value: "videos")
        ]
        
        guard let url = urlComponents?.url else { return }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        if let token = UserDefaults.standard.string(forKey: AppConfig.authTokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: SearchResponse.self, decoder: jsonDecoder)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("[SearchService] Video search error: \(error)")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                let videos = response.results.compactMap { result -> Track? in
                    guard case .video(let track) = result.item else { return nil }
                    return track
                }
                
                // Сортируем по дате (сверху новое)
                let sortedVideos = videos.sorted { $0.dateAdded > $1.dateAdded }
                
                if loadMore {
                    self.videoResults.append(contentsOf: sortedVideos)
                    // Пересортировываем весь массив после добавления
                    self.videoResults.sort { $0.dateAdded > $1.dateAdded }
                } else {
                    self.videoResults = sortedVideos
                }
                
                self.videoHasMore[query] = videos.count >= 20
                if videos.count >= 20 {
                    self.videoPage[query] = (self.videoPage[query] ?? 1) + 1
                }
            }
            .store(in: &cancellables)
    }
    
    func searchMusic(query: String, loadMore: Bool) {
        if !loadMore {
            musicResults = []
            musicPage[query] = 1
            musicHasMore[query] = true
        }
        
        guard let page = musicPage[query], musicHasMore[query] == true else { return }
        
        var urlComponents = URLComponents(string: "\(baseURL)/api/search")
        urlComponents?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "filter", value: "music")
        ]
        
        guard let url = urlComponents?.url else { return }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        if let token = UserDefaults.standard.string(forKey: AppConfig.authTokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: SearchResponse.self, decoder: jsonDecoder)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("[SearchService] Music search error: \(error)")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                // Бэкенд возвращает все как Track
                let tracks = response.results.compactMap { result -> Track? in
                    guard case .video(let track) = result.item else { return nil }
                    return track
                }
                
                // Сортируем по дате (сверху новое)
                let sortedTracks = tracks.sorted { $0.dateAdded > $1.dateAdded }
                
                if loadMore {
                    self.musicResults.append(contentsOf: sortedTracks)
                    // Пересортировываем весь массив после добавления
                    self.musicResults.sort { $0.dateAdded > $1.dateAdded }
                } else {
                    self.musicResults = sortedTracks
                }
                
                self.musicHasMore[query] = tracks.count >= 20
                if tracks.count >= 20 {
                    self.musicPage[query] = (self.musicPage[query] ?? 1) + 1
                }
            }
            .store(in: &cancellables)
    }
    
    func searchPhotos(query: String, loadMore: Bool) {
        if !loadMore {
            photoResults = []
            photoPage[query] = 1
            photoHasMore[query] = true
        }
        
        guard let page = photoPage[query], photoHasMore[query] == true else { return }
        
        var urlComponents = URLComponents(string: "\(baseURL)/api/search")
        urlComponents?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "filter", value: "photos")
        ]
        
        guard let url = urlComponents?.url else { return }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        if let token = UserDefaults.standard.string(forKey: AppConfig.authTokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: SearchResponse.self, decoder: jsonDecoder)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("[SearchService] Photo search error: \(error)")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                // Бэкенд возвращает все как Track
                let tracks = response.results.compactMap { result -> Track? in
                    guard case .video(let track) = result.item else { return nil }
                    return track
                }
                
                // Сортируем по дате (сверху новое)
                let sortedTracks = tracks.sorted { $0.dateAdded > $1.dateAdded }
                
                if loadMore {
                    self.photoResults.append(contentsOf: sortedTracks)
                    // Пересортировываем весь массив после добавления
                    self.photoResults.sort { $0.dateAdded > $1.dateAdded }
                } else {
                    self.photoResults = sortedTracks
                }
                
                self.photoHasMore[query] = tracks.count >= 20
                if tracks.count >= 20 {
                    self.photoPage[query] = (self.photoPage[query] ?? 1) + 1
                }
            }
            .store(in: &cancellables)
    }
    
    func searchAuthors(query: String, loadMore: Bool) {
        if !loadMore {
            authorResults = []
            authorPage[query] = 1
            authorHasMore[query] = true
        }
        
        guard let page = authorPage[query], authorHasMore[query] == true else { return }
        
        var urlComponents = URLComponents(string: "\(baseURL)/api/search")
        urlComponents?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "filter", value: "authors")
        ]
        
        guard let url = urlComponents?.url else { return }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        if let token = UserDefaults.standard.string(forKey: AppConfig.authTokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: SearchResponse.self, decoder: jsonDecoder)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("[SearchService] Author search error: \(error)")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                let authors = response.results.compactMap { result -> AuthorResult? in
                    guard case .author(let author) = result.item else { return nil }
                    return author
                }
                
                if loadMore {
                    self.authorResults.append(contentsOf: authors)
                } else {
                    self.authorResults = authors
                }
                
                self.authorHasMore[query] = authors.count >= 20
                if authors.count >= 20 {
                    self.authorPage[query] = (self.authorPage[query] ?? 1) + 1
                }
            }
            .store(in: &cancellables)
    }
    
    func loadPopularVideos(force: Bool = false) {
        currentQuery = ""
        // Загружаем все типы при пустом запросе
        searchVideos(query: "", loadMore: false)
        searchMusic(query: "", loadMore: false)
        searchPhotos(query: "", loadMore: false)
        searchAuthors(query: "", loadMore: false)
    }
    
    func clearResults() {
        videoResults = []
        musicResults = []
        photoResults = []
        authorResults = []
        videoPage = [:]
        musicPage = [:]
        photoPage = [:]
        authorPage = [:]
        videoHasMore = [:]
        musicHasMore = [:]
        photoHasMore = [:]
        authorHasMore = [:]
        currentQuery = ""
        error = nil
    }
    
    // Для обратной совместимости
    var searchResults: [SearchResultItem] {
        get {
            switch currentFilter {
            case .all:
                return allResults
            case .videos:
                return videoResults.map { .video($0) }
            case .music:
                return musicResults.map { .video($0) }
        case .photos:
            return photoResults.map { .video($0) }
            case .authors:
                return authorResults.map { .author($0) }
            }
        }
    }
    
    var hasMoreResults: Bool {
        switch currentFilter {
        case .all:
            return (videoHasMore[currentQuery] == true) || 
                   (musicHasMore[currentQuery] == true) || 
                   (photoHasMore[currentQuery] == true) || 
                   (authorHasMore[currentQuery] == true)
        case .videos:
            return videoHasMore[currentQuery] == true
        case .music:
            return musicHasMore[currentQuery] == true
        case .photos:
            return photoHasMore[currentQuery] == true
        case .authors:
            return authorHasMore[currentQuery] == true
        }
    }
    
    private var currentFilter: SearchFilter = .all
    
    func loadMoreResults() {
        loadMore(filter: currentFilter)
    }
    
    func searchWithPagination(
        query: String?,
        filter: SearchFilter = .videos,
        page: Int,
        pageSize: Int = 20,
        userId: UUID? = nil,
        trackIds: [UUID]? = nil,
        completion: @escaping (Int, [Track], Bool) -> Void
    ) {
        var urlComponents = URLComponents(string: "\(baseURL)/api/search")
        
        let filterValue: String
        switch filter {
        case .videos:
            filterValue = "videos"
        case .music:
            filterValue = "music"
        case .photos:
            filterValue = "photos"
        case .authors:
            filterValue = "authors"
        case .all:
            filterValue = "all"
        }
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(pageSize)"),
            URLQueryItem(name: "filter", value: filterValue)
        ]
        
        if let q = query, !q.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: q))
        }
        
        if let userId = userId {
            queryItems.append(URLQueryItem(name: "user_id", value: userId.uuidString))
            print("[SearchService] searchWithPagination: отправляем user_id=\(userId.uuidString)")
        } else {
            print("[SearchService] searchWithPagination: user_id не передан (nil)")
        }
        
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            completion(page, [], false)
            return
        }
        
        print("[SearchService] searchWithPagination: URL=\(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        if let token = UserDefaults.standard.string(forKey: AppConfig.authTokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("[SearchService] searchWithPagination: HTTP статус=\(httpResponse.statusCode)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("[SearchService] searchWithPagination: сырой JSON ответ (первые 1000 символов): \(String(jsonString.prefix(1000)))")
                    }
                }
                return data
            }
            .decode(type: SearchResponse.self, decoder: jsonDecoder)
            .receive(on: DispatchQueue.main)
            .sink { result in
                if case .failure(let error) = result {
                    print("[SearchService] searchWithPagination error: \(error)")
                    if let decodingError = error as? DecodingError {
                        print("[SearchService] DecodingError details: \(decodingError)")
                    }
                    completion(page, [], false)
                }
            } receiveValue: { response in
                print("[SearchService] searchWithPagination: получено \(response.results.count) результатов для фильтра \(filter.rawValue)")
                
                if let jsonData = try? JSONEncoder().encode(response),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("[SearchService] searchWithPagination: JSON ответ (первые 500 символов): \(String(jsonString.prefix(500)))")
                }
                
                for (index, result) in response.results.enumerated() {
                    switch result.item {
                    case .video(let track):
                        let contentType = track.contentType?.lowercased() ?? ""
                        print("[SearchService] результат \(index): \(contentType), id=\(track.id), title=\(track.title)")
                    case .author:
                        print("[SearchService] результат \(index): author")
                    }
                }
                
                let tracks: [Track]
                
                // Бэкенд возвращает все как VideoResponse (Track), просто декодируем
                tracks = response.results.compactMap { result -> Track? in
                    // Все типы контента (video, music, photo) декодируются как .video(Track)
                    switch result.item {
                    case .video(let track):
                        return track
                    case .author:
                        return nil
                    }
                }
                
                print("[SearchService] searchWithPagination: конвертировано \(tracks.count) треков для фильтра \(filter.rawValue)")
                
                // Фильтруем по trackIds если нужно
                var filteredTracks = tracks
                if let trackIds = trackIds {
                    filteredTracks = tracks.filter { trackIds.contains($0.id) }
                }
                
                let hasMore = tracks.count >= pageSize
                completion(page, filteredTracks, hasMore)
            }
            .store(in: &cancellables)
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
