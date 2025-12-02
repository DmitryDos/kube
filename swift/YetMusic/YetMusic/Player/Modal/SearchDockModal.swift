import SwiftUI

struct SearchDockModal: View {
    @StateObject private var searchService = SearchService.shared
    @State private var searchText: String = ""
    
    private var safeAreaTrailing: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.right
        }
        return 0
    }
    
    var body: some View {
        GeometryReader { geo in
            let modalWidth = geo.size.width * 0.35
            let trailingPadding = safeAreaTrailing > 0 ? safeAreaTrailing : 0
            
            HStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Поисковая строка
                    ExpandableSearchBar(
                        text: $searchText,
                        placeholder: "Поиск видео",
                        onSubmit: {
                            performSearch()
                        },
                        onClear: {
                            searchService.clearResults()
                            searchService.loadPopularVideos(force: true)
                        }
                    )
                    .padding(.top, 8)
                    
                    // Результаты поиска
                    SearchVideoResultsView()
                        .padding(.vertical, 16)
                }
                .appBackground()
                .overlay(ModalMarkerView().allowsHitTesting(false))
                .frame(width: modalWidth)
                .frame(maxHeight: .infinity)
                .padding(.trailing, trailingPadding)
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchService.loadPopularVideos(force: true)
            return
        }
        searchService.search(query: searchText, filter: .videos)
    }
}


