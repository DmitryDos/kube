//
//  SearchMusicView.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI
import Combine

struct SearchMusicView: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @ObservedObject private var queueService = QueueService.shared
    @StateObject private var playlistService = PlaylistService.shared
    @Environment(\.currentPage) private var currentPage
    
    let track: Track
    let onLongPress: () -> Void
    
    @State private var showLikeAnimation = false
    @State private var showAddToQueueAnimation = false
    @State private var cancellables = Set<AnyCancellable>()
    @ObservedObject private var authService = AuthService.shared
    
    init(track: Track, onLongPress: @escaping () -> Void) {
        self.track = track
        self.onLongPress = onLongPress
    }
    
    private var isLiked: Bool {
        return false
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Обложка музыки (как у видео - 16:9)
            AsyncTrackImage(track: track, canOpenModal: false)
                .aspectRatio(16/9, contentMode: .fill)
                .clipped()
            
            // Квадрат с иконкой ноты поверх картинки (справа сверху)
            VStack {
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeObserver.contrastColor.opacity(0.9))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(themeObserver.themedAccentColor)
                        )
                        .padding(8)
                }
                Spacer()
            }
            
            // Информация о музыке
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeObserver.isDarkTheme ? themeObserver.whiteColor : themeObserver.textColor)
                        .lineLimit(1)
                    
                    Text(track.desc)
                        .font(.system(size: 12))
                        .foregroundColor(themeObserver.isDarkTheme ? themeObserver.whiteColor.opacity(0.9) : themeObserver.textColor.opacity(0.8))
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(themeObserver.backgroundGlassColor)
            .cornerRadius(8)
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
            
            // Кнопка лайка (слева сверху) - только для авторизованных пользователей
            if authService.isAuthenticated {
                VStack {
                    HStack {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isLiked ? themeObserver.likeColor : themeObserver.themedAccentColor)
                            .frame(width: 32, height: 32)
                            .background(themeObserver.contrastColor)
                            .cornerRadius(8)
                            .scaleEffect(showLikeAnimation ? 1.2 : 1.0)
                            .highPriorityGesture(
                                TapGesture()
                                    .onEnded { toggleLike() }
                            )
                        
                        Spacer()
                    }
                    Spacer()
                }
                .padding(8)
            }
            
            // Кнопка добавить в очередь (справа снизу) - как у видео
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "text.badge.plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(themeObserver.themedAccentColor)
                        .frame(width: 32, height: 32)
                        .background(themeObserver.contrastColor)
                        .cornerRadius(8)
                        .scaleEffect(showAddToQueueAnimation ? 1.2 : 1.0)
                        .highPriorityGesture(
                            TapGesture()
                                .onEnded { addToQueue() }
                        )
                }
            }
            .padding(8)
        }
        .frame(maxWidth: UIScreen.main.bounds.height * 0.5 * 16 / 9)
        .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
        .highPriorityGesture(
            TapGesture(count: 2)
                .onEnded {
                    playMusicAndStartPiP()
                }
        )
        .onTapGesture {
            openPlayer()
        }
        .onLongPressGesture(minimumDuration: 0.2) {
            onLongPress()
        }
        .onDisappear {
            // Очищаем подписки при размонтировании
            cancellables.removeAll()
        }
    }
    
    private func toggleLike() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showLikeAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showLikeAnimation = false
            }
        }
        
        print("Toggle like for: \(track.title)")
    }
    
    private func openPlayer() {
        // Загружаем трек в плеер
        queueService.playTrack(track)
        HistoryService.shared.recordPlayed(track)
        
        // Открываем плеер (страница 0)
        currentPage.wrappedValue = 0
    }
    
    private func playMusicAndStartPiP() {
        // Для аудио PiP не работает, просто запускаем воспроизведение
        // (двойной тап работает так же, как одинарный)
        openPlayer()
    }
    
    private func addToQueue() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showAddToQueueAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showAddToQueueAnimation = false
            }
        }
        
        queueService.addToWishlist(track)
    }
}

