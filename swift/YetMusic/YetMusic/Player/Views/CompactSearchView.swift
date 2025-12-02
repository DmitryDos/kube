//
//  CompactSearchView.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI

/// Компактная версия поиска для встраивания в контроллы плеера - использует существующие компоненты
struct CompactSearchView: View {
    @StateObject private var searchService = SearchService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @State private var searchText: String = ""
    
    @AppStorage("playerSearchVisible") private var isSearchVisible = true
    
    var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    if isSearchVisible {
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
                        
                        // Используем существующий компонент результатов поиска
                        SearchVideoResultsView()
                            .ignoresSafeArea(edges: .vertical)
                            // .padding(.top, safeAreaTop)
                            // .padding(.bottom, safeAreaBottom)
                            .frame(maxHeight: .infinity)
                    } else {
                        Spacer()
                    }
                }
                .padding(.vertical, 8)
                .padding(.top, safeAreaTop)
                .padding(.bottom, safeAreaBottom)
                .background(themeObserver.backgroundGlassColor)
                .frame(width: isSearchVisible ? 250 : 0)
                .frame(maxHeight: .infinity)
                
                VStack {
                    Button {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            isSearchVisible.toggle()
                        }
                    } label: {
                        Image(systemName: isSearchVisible ? "chevron.left" : "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeObserver.textColor)
                            .frame(width: 32, height: 96) // Высота увеличена в 3 раза (32 * 3 = 96)
                            .background(themeObserver.backgroundGlassColor)
                            .clipShape(.rect(bottomTrailingRadius: 8, topTrailingRadius: 8))
                            .animation(nil, value: isSearchVisible)
                    }
                    .padding(.top, safeAreaTop + 80)

                    Spacer()
                }
            }
        }
        .onAppear {
            if searchService.videoResults.isEmpty {
                searchService.loadPopularVideos(force: true)
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

