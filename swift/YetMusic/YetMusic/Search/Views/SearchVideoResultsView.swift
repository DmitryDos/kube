import SwiftUI

/// Переиспользуемый компонент для отображения только результатов поиска видео (без чипсов)
struct SearchVideoResultsView: View {
    @StateObject private var searchService = SearchService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Environment(\.isLandscape) private var isLandscape
    
    var body: some View {
        Group {
            if searchService.isLoading && searchService.searchResults.isEmpty {
                loadingView
            } else if let error = searchService.error {
                errorView(error: error)
            } else if videoResults.isEmpty {
                emptyView
            } else {
                resultsView
            }
        }
    }
    
    private var videoResults: [Track] {
        searchService.searchResults.compactMap { item in
            if case .video(let track) = item {
                return track
            }
            return nil
        }
    }
    
    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(videoResults, id: \.id) { track in
                    TrackCardView(
                        track: track,
                        onTap: {
                            QueueService.shared.playTrack(track)
                            HistoryService.shared.recordPlayed(track)
                        },
                        onLongPress: {
                        showVideoInfo(track)
                    }
                    )
                    .onAppear {
                        if isLastItem(track, in: videoResults) {
                            searchService.loadMoreResults()
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
    
    private func isLastItem(_ track: Track, in list: [Track]) -> Bool {
        guard let lastItem = list.last else { return false }
        return track.id == lastItem.id
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "film")
                .font(.system(size: 50))
                .foregroundColor(themeObserver.themedAccentColor)
            
            Text("Популярные видео")
                .font(.headline)
                .foregroundColor(themeObserver.themedPrimaryColor)
            
            Text("Начните поиск чтобы найти видео")
                .font(.body)
                .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func showVideoInfo(_ track: Track) {
        ModalProvider.shared.showModalContainer(EditVideoModal(track: track, isReadOnly: true))
    }
}

