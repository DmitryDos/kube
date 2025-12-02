//
//  SearchVideoView.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI
import AVFoundation
import Combine

struct SearchVideoView: View {
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
    
    private var isLiked: Bool {
        return false
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncTrackImage(track: track, canOpenModal: false)
                .aspectRatio(16/9, contentMode: .fill)
                .clipped()

                // Информация о видео
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
                
                // Кнопка лайка (слева сверху) - только для авторизованных пользователей и не для своих треков
                if authService.isAuthenticated {
                    let isOwnTrack = {
                        guard let ownerId = track.ownerUserId,
                              let currentUserId = authService.currentUser?.id else {
                            return false
                        }
                        return ownerId == currentUserId
                    }()
                    
                    if !isOwnTrack {
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
                }

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
            }
        .frame(maxWidth: UIScreen.main.bounds.height * 0.5 * 16 / 9)
        .highPriorityGesture(
            TapGesture(count: 2)
                .onEnded {
                    playVideoAndStartPiP()
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
    
    private func openPlayer() {
        // Загружаем трек в плеер
        queueService.playTrack(track)
        HistoryService.shared.recordPlayed(track)
        
        // Открываем модалку на весь экран
        ModalProvider.shared.show(
            FullScreenVideoModal(track: track),
            requiresBackground: false,
            isModalContainer: true,
            disableDismissOnTap: true
        )
    }
    
    private func playVideoAndStartPiP() {
        // Отменяем предыдущие подписки
        cancellables.removeAll()
        
        // Запускаем трек через очередь
        queueService.playTrack(track)
        
        // Ждем, пока трек загрузится и начнет играть
        let audioService = AudioPlayerService.shared
        
        // Подписываемся на изменение состояния воспроизведения
        let trackId = track.id
        audioService.$trackInfo
            .sink { trackInfo in
                // Проверяем, что это наш трек и он играет
                if trackInfo.track?.id == trackId && trackInfo.isPlaying {
                    // Трек начал играть, запускаем PiP с небольшой задержкой
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        PiPController.shared.startPiP()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Таймаут на случай, если трек не начнет играть
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            cancellables.removeAll()
        }
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
}
