import SwiftUI

struct SearchView: View {
    @StateObject private var searchService = SearchService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    
    @State private var searchText: String = ""
    @State private var selectedFilter: SearchFilter = .all
    @State private var pendingSearch: DispatchWorkItem?
    
    private var filteredResults: [SearchResultItem] {
        switch selectedFilter {
        case .all:
            return searchService.searchResults
        case .authors:
            return searchService.searchResults.filter {
                if case .author = $0 { return true }
                return false
            }
        case .videos:
            return searchService.searchResults.filter {
                if case .video = $0 { return true }
                return false
            }
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                searchBar
                
                FilterChipsView(
                    items: SearchFilter.allCases,
                    selectedItem: $selectedFilter
                ) { filter in
                    performSearch()
                }
                
                if searchService.isLoading && searchService.searchResults.isEmpty {
                    loadingView
                } else if let error = searchService.error {
                    errorView(error: error)
                } else if filteredResults.isEmpty {
                    emptyView
                } else {
                    resultsView
                }
                
                Spacer()
            }
        }
        .onAppear {
            if searchService.searchResults.isEmpty {
                searchService.loadPopularVideos()
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeObserver.themedPrimaryColor)
                
                TextField("Поиск видео и авторов", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(themeObserver.themedPrimaryColor)
                    .onChange(of: searchText) { newValue in
                        scheduleDebouncedSearch()
                        if newValue.isEmpty {
                            searchService.loadPopularVideos()
                        }
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchService.clearResults()
                        searchService.loadPopularVideos()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.6))
                    }
                }
            }
            .padding(12)
            .background(themeObserver.contrastColor)
            .cornerRadius(50)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 12)
    }
    
    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredResults) { item in
                    switch item {
                    case .video(let video):
                        SearchVideoView(video: video) {
                            showVideoInfo(video)
                        }
                        .onAppear {
                            if isLastItem(item, in: filteredResults) {
                                searchService.loadMoreResults()
                            }
                        }
                        
                    case .author(let author):
                        SearchAuthorView(author: author) {
                            showAuthorInfo(author)
                        }
                        .onAppear {
                            if isLastItem(item, in: filteredResults) {
                                searchService.loadMoreResults()
                            }
                        }
                    }
                }
                
                if searchService.isLoading && !searchService.searchResults.isEmpty {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(themeObserver.themedAccentColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    private func isLastItem(_ item: SearchResultItem, in list: [SearchResultItem]) -> Bool {
        guard let lastItem = list.last else { return false }
        return item.id == lastItem.id
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .tint(themeObserver.themedAccentColor)
                .padding()
            
            Text("Ищем...")
                .foregroundColor(themeObserver.themedPrimaryColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(themeObserver.themedAccentColor)
            
            Text("Ошибка поиска")
                .font(.headline)
                .foregroundColor(themeObserver.themedPrimaryColor)
            
            Text(error)
                .font(.body)
                .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Повторить") {
                performSearch()
            }
            .padding()
            .background(themeObserver.themedAccentColor)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "film" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(themeObserver.themedAccentColor)
            
            Text(searchText.isEmpty ? "Популярные видео" : "Ничего не найдено")
                .font(.headline)
                .foregroundColor(themeObserver.themedPrimaryColor)
            
            Text(searchText.isEmpty ?
                 "Начните поиск чтобы найти видео и авторов" :
                 "Попробуйте изменить запрос или фильтр")
                .font(.body)
                .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func scheduleDebouncedSearch() {
        pendingSearch?.cancel()
        
        let work = DispatchWorkItem { [searchText] in
            performSearch(with: searchText)
        }
        
        pendingSearch = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }
    
    private func performSearch() {
        performSearch(with: searchText)
    }
    
    private func performSearch(with query: String) {
        guard !query.isEmpty else {
            searchService.loadPopularVideos()
            return
        }
        searchService.search(query: query, filter: selectedFilter)
    }
    
    private func showVideoInfo(_ video: VideoResult) {
        ModalProvider.shared.show(VideoInfoModal(video: video))
    }
    
    private func showAuthorInfo(_ author: AuthorResult) {
        ModalProvider.shared.show(AuthorInfoModal(author: author))
    }
}
