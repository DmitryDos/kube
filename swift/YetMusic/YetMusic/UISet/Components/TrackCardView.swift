//
//  TrackCardView.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI
import Combine

struct TrackCardView: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @ObservedObject private var queueService = QueueService.shared
    @ObservedObject private var authService = AuthService.shared
    @Environment(\.currentPage) private var currentPage
    
    let track: Track
    let onTap: () -> Void
    let onLongPress: () -> Void
    var onAddToQueue: (() -> Void)? = nil
    var showAddToQueueButton: Bool = true
    var isEditingMode: Bool = false
    var isSelected: Bool = false
    var onToggle: (() -> Void)? = nil
    
    @State private var cancellables = Set<AnyCancellable>()
    
    private var contentType: String {
        track.contentType?.lowercased() ?? ""
    }
    
    private var isPhoto: Bool {
        contentType == "image"
    }
    
    private var isAudio: Bool {
        contentType == "audio"
    }
    
    private var aspectRatio: CGFloat? {
        isPhoto ? nil : 16/9
    }
    
    private var imageContentMode: ContentMode {
        isPhoto ? .fit : .fill
    }
    
    private var isInQueue: Bool {
        queueService.wishlistQueue.contains(where: { $0.id == track.id })
    }
    
    var body: some View {
        Group {
            if isPhoto {
                photoView
            } else {
                mediaView
            }
        }
    }
    
    // Вид для фото - стеклянный блок снизу как у видео/музыки
    private var photoView: some View {
        ZStack(alignment: .bottom) {
            AsyncTrackImage(
                imageURL: track.imageURL,
                cornerRadius: 10,
                imageContentMode: .fit,
                showBackground: false,
                isPhoto: true,
                canOpenModal: false,
                track: track
            )
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(themeObserver.contrastColor.opacity(0.3), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .highPriorityGesture(
                TapGesture(count: 2)
                    .onEnded {
                        // Двойной клик для фото не нужен
                        onTap()
                    }
            )
            .onTapGesture {
                // Одинарный клик - открываем фото
                onTap()
            }
            .onLongPressGesture(minimumDuration: 0.2) {
                onLongPress()
            }
            
            // Информация о фото - стеклянный блок снизу
            if !track.title.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeObserver.isDarkTheme ? themeObserver.whiteColor : themeObserver.textColor)
                            .lineLimit(1)
                        
                        if !track.desc.isEmpty {
                            Text(track.desc)
                                .font(.system(size: 12))
                                .foregroundColor(themeObserver.isDarkTheme ? themeObserver.whiteColor.opacity(0.9) : themeObserver.textColor.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(themeObserver.backgroundGlassColor)
                .cornerRadius(8)
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // Вид для музыки/видео - текст поверх, кнопки поверх
    private var mediaView: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width
            let cardHeight = cardWidth / (16/9)
            
            ZStack(alignment: .bottom) {
                AsyncTrackImage(
                    track: track,
                    cornerRadius: 10,
                    imageContentMode: imageContentMode,
                    canOpenModal: false
                )
                .frame(width: cardWidth, height: cardHeight)
                .aspectRatio(16/9, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(themeObserver.contrastColor.opacity(0.3), lineWidth: 1)
                )
                
                if isEditingMode {
                    VStack {
                        HStack {
                            Button {
                                onToggle?()
                            } label: {
                                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 20))
                                    .foregroundColor(isSelected ? themeObserver.themedAccentColor : themeObserver.whiteColor)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(themeObserver.blackColor.opacity(0.7)))
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(8)
                }
                
                // Иконка для аудио (справа сверху)
                if isAudio {
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
                }
                
                // Информация о треке
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
            }
            .frame(width: cardWidth, height: cardHeight)
            .overlay(
                Group {
                    if !isEditingMode && showAddToQueueButton && !isInQueue {
                        Button {
                            onAddToQueue?() ?? addToQueueDefault()
                        } label: {
                            Image(systemName: "text.badge.plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(themeObserver.themedAccentColor)
                                .frame(width: 32, height: 32)
                                .background(themeObserver.contrastColor)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .offset(x: 4, y: 4)
                    }
                },
                alignment: .bottomTrailing
            )
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            .onLongPressGesture(minimumDuration: 0.2) {
                onLongPress()
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
        .padding(2)
    }
    
    private func addToQueueDefault() {
        queueService.addToWishlist(track)
    }
    
    private func openPlayer() {
        if isPhoto {
            // Для фото открываем модалку с фото
            onTap()
        } else if isAudio {
            // Для аудио просто запускаем воспроизведение
            queueService.playTrack(track)
            HistoryService.shared.recordPlayed(track)
        } else {
            // Для видео открываем модалку на весь экран
            queueService.playTrack(track)
            HistoryService.shared.recordPlayed(track)
            ModalProvider.shared.show(
                FullScreenVideoModal(track: track),
                requiresBackground: false,
                isModalContainer: true,
                disableDismissOnTap: true
            )
        }
    }
    
    private func playTrackAndStartPiP() {
        // Отменяем предыдущие подписки
        cancellables.removeAll()
        
        // Запускаем трек через очередь
        queueService.playTrack(track)
        HistoryService.shared.recordPlayed(track)
        
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
}

