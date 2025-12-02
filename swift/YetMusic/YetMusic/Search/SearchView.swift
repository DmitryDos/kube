import SwiftUI

struct SearchView: View {
    @StateObject private var searchService = SearchService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Environment(\.isLandscape) private var isLandscape
    
    @State private var searchText: String = ""
    @State private var selectedFilter: SearchFilter = .all
    @State private var pendingSearch: DispatchWorkItem?
    @State private var selectedFilters: Set<String> = []
    @State private var sortOrder: FilterSettingsModal.SortOrder = .newest
    @State private var hasActiveFilters: Bool = false
    
    private var filteredResults: [SearchResultItem] {
        switch selectedFilter {
        case .all:
            return searchService.allResults
        case .authors:
            return searchService.authorResults.map { .author($0) }
        case .videos:
            return searchService.videoResults.map { .video($0) }
        case .music:
            return searchService.musicResults.map { .video($0) }
        case .photos:
            return searchService.photoResults.map { .video($0) }
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                searchBar
                
                if hasActiveFilters {
                    Button {
                        selectedFilters.removeAll()
                        sortOrder = .newest
                        hasActiveFilters = false
                    } label: {
                        Text("Сбросить фильтры")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeObserver.themedAccentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(themeObserver.contrastColor)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, isLandscape ? 0 : 12)
                    .padding(.vertical, 8)
                } else {
                    HStack(spacing: 8) {
                        Button {
                            ModalProvider.shared.showModalContainer(
                                FilterSettingsModal(
                                    selectedFilters: $selectedFilters,
                                    sortOrder: $sortOrder,
                                    availableFilters: SearchFilter.allCases.map { $0.rawValue },
                                    onApply: {
                                        hasActiveFilters = !selectedFilters.isEmpty || sortOrder != .newest
                                    },
                                    onReset: {
                                        selectedFilters.removeAll()
                                        sortOrder = .newest
                                        hasActiveFilters = false
                                    }
                                )
                            )
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 20))
                                .foregroundColor(themeObserver.themedAccentColor)
                                .frame(width: 44, height: 44)
                                .background(themeObserver.contrastColor)
                                .cornerRadius(12)
                        }
                
                FilterChipsView(
                    items: SearchFilter.allCases,
                    selectedItem: $selectedFilter
                ) { filter in
                    // При переключении чипсов проверяем, нужно ли загрузить данные для выбранного фильтра
                    if !searchText.isEmpty {
                        // Если есть запрос, загружаем данные для выбранного фильтра, если они еще не загружены
                        switch filter {
                        case .photos:
                            if searchService.photoResults.isEmpty {
                                searchService.searchPhotos(query: searchText, loadMore: false)
                            }
                        case .music:
                            if searchService.musicResults.isEmpty {
                                searchService.searchMusic(query: searchText, loadMore: false)
                            }
                        case .authors:
                            if searchService.authorResults.isEmpty {
                                searchService.searchAuthors(query: searchText, loadMore: false)
                            }
                        case .videos:
                            if searchService.videoResults.isEmpty {
                                searchService.searchVideos(query: searchText, loadMore: false)
                            }
                        case .all:
                            // Для "всё" загружаем все типы, если они еще не загружены
                            if searchService.videoResults.isEmpty {
                                searchService.searchVideos(query: searchText, loadMore: false)
                            }
                            if searchService.musicResults.isEmpty {
                                searchService.searchMusic(query: searchText, loadMore: false)
                            }
                            if searchService.photoResults.isEmpty {
                                searchService.searchPhotos(query: searchText, loadMore: false)
                            }
                            if searchService.authorResults.isEmpty {
                                searchService.searchAuthors(query: searchText, loadMore: false)
                            }
                        }
                    }
                }
                .padding(.horizontal, isLandscape ? 0 : 12)
                    }
                }
                
                if searchService.isLoading && filteredResults.isEmpty {
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

        }
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
    
    private var searchBar: some View {
        HStack {
        ExpandableSearchBar(
            text: $searchText,
            placeholder: "Поиск видео и авторов",
            onSubmit: {
                performSearch()
            },
            onClear: {
                searchService.clearResults()
                searchService.loadPopularVideos(force: true)
            }
        )

            Spacer()
                .frame(width: isLandscape ? 0 : 54)
        }
    }
    
    private var resultsView: some View {
        ScrollView {
            if isLandscape && selectedFilter == .photos {
                // Для фото в горизонтальном режиме - masonry grid
                HStack(alignment: .top, spacing: 2) {
                    ForEach(0..<2, id: \.self) { columnIndex in
                        VStack(spacing: 2) {
                            ForEach(photoItemsForColumn(columnIndex), id: \.id) { track in
                                TrackCardView(
                                    track: track,
                                    onTap: {
                                            ModalProvider.shared.show(PhotoViewModal(track: track, isReadOnly: true), requiresBackground: false, disableDismissOnTap: true)
                                    },
                                    onLongPress: {
                                    showPhotoInfo(track)
                                }
                                )
                                .onAppear {
                                    if isLastPhoto(track, in: photoItems) {
                                        searchService.loadMoreResults()
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 8)
            } else if isLandscape {
                // В горизонтальном режиме для остальных - грид (2 в ширину)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                ForEach(filteredResults, id: \.id) { item in
                    switch item {
                    case .video(let track):
                        // Определяем тип контента по contentType
                        let contentType = track.contentType?.lowercased() ?? ""
                        TrackCardView(
                            track: track,
                            onTap: {
                                if contentType == "image" {
                                            ModalProvider.shared.show(PhotoViewModal(track: track, isReadOnly: true), requiresBackground: false, disableDismissOnTap: true)
                                        } else if contentType == "audio" {
                                            QueueService.shared.playTrack(track)
                                            HistoryService.shared.recordPlayed(track)
                                } else {
                                            // Для видео открываем модалку на весь экран
                                    QueueService.shared.playTrack(track)
                                    HistoryService.shared.recordPlayed(track)
                                            ModalProvider.shared.show(
                                                FullScreenVideoModal(track: track),
                                                requiresBackground: false,
                                                isModalContainer: true,
                                                disableDismissOnTap: true
                                            )
                                }
                            },
                            onLongPress: {
                            if contentType == "audio" {
                                    showMusicInfo(track)
                            } else if contentType == "image" {
                                    showPhotoInfo(track)
                            } else {
                                    showVideoInfo(track)
                                }
                            },
                            onAddToQueue: {
                                QueueService.shared.addToWishlist(track)
                            }
                        )
                        .onAppear {
                            // Проверяем, что это один из последних элементов (не обязательно самый последний)
                            let index = filteredResults.firstIndex(where: { $0.id == item.id }) ?? -1
                            if index >= filteredResults.count - 3 {
                                searchService.loadMoreResults()
                            }
                        }
                        
                    case .author(let author):
                        SearchAuthorView(author: author) {
                            showAuthorInfo(author)
                        }
                        .onAppear {
                            // Проверяем, что это один из последних элементов (не обязательно самый последний)
                            let index = filteredResults.firstIndex(where: { $0.id == item.id }) ?? -1
                            if index >= filteredResults.count - 3 {
                                searchService.loadMoreResults()
                            }
                        }
                        }
                    }
                    
                    if searchService.isLoading && !filteredResults.isEmpty {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(themeObserver.themedAccentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .gridCellColumns(2)
                    }
                }
                .padding(.horizontal, 8)
            } else {
                // В вертикальном режиме - всегда стек
                LazyVStack(spacing: 12) {
                    ForEach(filteredResults, id: \.id) { item in
                        switch item {
                        case .video(let track):
                            // Определяем тип контента по contentType
                            let contentType = track.contentType?.lowercased() ?? ""
                        TrackCardView(
                            track: track,
                            onTap: {
                                if contentType == "image" {
                                            ModalProvider.shared.show(PhotoViewModal(track: track, isReadOnly: true), requiresBackground: false, disableDismissOnTap: true)
                                        } else if contentType == "audio" {
                                            QueueService.shared.playTrack(track)
                                            HistoryService.shared.recordPlayed(track)
                                } else {
                                            // Для видео открываем модалку на весь экран
                                    QueueService.shared.playTrack(track)
                                    HistoryService.shared.recordPlayed(track)
                                            ModalProvider.shared.show(
                                                FullScreenVideoModal(track: track),
                                                requiresBackground: false,
                                                isModalContainer: true,
                                                disableDismissOnTap: true
                                            )
                                }
                            },
                            onLongPress: {
                                if contentType == "audio" {
                                        showMusicInfo(track)
                                } else if contentType == "image" {
                                        showPhotoInfo(track)
                                } else {
                                        showVideoInfo(track)
                                }
                            },
                            onAddToQueue: {
                                QueueService.shared.addToWishlist(track)
                            }
                        )
                            .onAppear {
                                // Проверяем, что это один из последних элементов (не обязательно самый последний)
                                let index = filteredResults.firstIndex(where: { $0.id == item.id }) ?? -1
                                if index >= filteredResults.count - 3 {
                                    searchService.loadMore(filter: selectedFilter)
                                }
                            }
                            
                        case .author(let author):
                            SearchAuthorView(author: author) {
                                showAuthorInfo(author)
                            }
                            .onAppear {
                                // Проверяем, что это один из последних элементов (не обязательно самый последний)
                                let index = filteredResults.firstIndex(where: { $0.id == item.id }) ?? -1
                                if index >= filteredResults.count - 3 {
                                    searchService.loadMore(filter: selectedFilter)
                                }
                            }
                    }
                }
                
                if searchService.isLoading && !filteredResults.isEmpty {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(themeObserver.themedAccentColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        .padding(.vertical, 16)
    }
    
    private var photoItems: [Track] {
        filteredResults.compactMap { item in
            if case .video(let track) = item, track.contentType?.lowercased() == "image" {
                return track
            }
            return nil
        }
    }
    
    private func photoItemsForColumn(_ columnIndex: Int) -> [Track] {
        photoItems.enumerated().compactMap { index, track in
            index % 2 == columnIndex ? track : nil
        }
    }
    
    private func isLastPhoto(_ track: Track, in list: [Track]) -> Bool {
        guard let lastTrack = list.last else { return false }
        return track.id == lastTrack.id
    }
    
    private func isLastItem(_ item: SearchResultItem, in list: [SearchResultItem]) -> Bool {
        guard let lastItem = list.last else { return false }
        return item.id == lastItem.id
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
            .foregroundColor(themeObserver.whiteColor)
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
    
    private func performSearch() {
        performSearch(with: searchText)
    }
    
    private func performSearch(with query: String) {
        guard !query.isEmpty else {
            searchService.loadPopularVideos(force: true)
            return
        }
        // При поиске загружаем все типы, если выбран "всё", иначе только выбранный тип
        if selectedFilter == .all {
            searchService.search(query: query, filter: .all)
        } else {
            searchService.search(query: query, filter: selectedFilter)
        }
    }
    
    private func showVideoInfo(_ track: Track) {
            ModalProvider.shared.showModalContainer(EditVideoModal(track: track, isReadOnly: true))
    }
    
    private func showAuthorInfo(_ author: AuthorResult) {
            ModalProvider.shared.showModalContainer(AuthorInfoModal(author: author))
    }
    
    private func showMusicInfo(_ track: Track) {
            ModalProvider.shared.showModalContainer(EditMusicModal(track: track, isReadOnly: true))
    }
    
    private func showPhotoInfo(_ track: Track) {
            ModalProvider.shared.showModalContainer(EditPhotoModal(track: track, isReadOnly: true))
    }
}
    
