//
//  CompactQueueView.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI

/// Компактная версия очереди для встраивания в контроллы плеера - аналогично CompactSearchView, но справа
struct CompactQueueView: View {
    @ObservedObject private var queueService = QueueService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    
    var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            let safeAreaTrailing = geometry.safeAreaInsets.trailing
            
            HStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Заголовок
                    HStack {
                        Text("Очередь")
                            .font(.headline)
                            .foregroundColor(themeObserver.textColor)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    
                    // Очередь
                    QueueOnlyView()
                        .padding(.top, safeAreaTop)
                        .padding(.bottom, safeAreaBottom)
                        .padding(.leading, 8)
                        .frame(maxHeight: .infinity)
                }
                .background(themeObserver.backgroundGlassColor)
                .frame(maxWidth: 250)
                .frame(maxHeight: .infinity)
            }
        }
    }
}
