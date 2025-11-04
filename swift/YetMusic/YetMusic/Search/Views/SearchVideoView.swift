//
//  SearchVideoView.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI
import AVFoundation

struct SearchVideoView: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @ObservedObject private var queueService = QueueService.shared
    @StateObject private var playlistService = PlaylistService.shared
    
    let video: VideoResult
    let onLongPress: () -> Void
    
    @State private var isPressed = false
    @State private var showLikeAnimation = false
    
    private var isLiked: Bool {
        return false
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: URL(string: video.imageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(themeObserver.contrastColor)
                        .overlay(
                            ProgressView()
                                .tint(themeObserver.themedAccentColor)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Rectangle()
                        .fill(themeObserver.contrastColor)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(themeObserver.themedPrimaryColor)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 180)
            .cornerRadius(12)
            .clipped()

            // Информация о видео
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(video.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeObserver.darkColor)
                        .lineLimit(1)
                    
                    Text(video.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(themeObserver.darkColor.opacity(0.7))
                        .lineLimit(1)
                    
                    if !video.description.isEmpty {
                        Text(video.description)
                            .font(.system(size: 11))
                            .foregroundColor(themeObserver.darkColor.opacity(0.6))
                            .lineLimit(2)
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
            
            // Кнопка лайка (слева сверху)
            VStack {
                HStack {
                    Button {
                        toggleLike()
                    } label: {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isLiked ? .red : themeObserver.themedPrimaryColor)
                            .frame(width: 32, height: 32)
                            .background(themeObserver.contrastColor)
                            .cornerRadius(8)
                            .scaleEffect(showLikeAnimation ? 1.2 : 1.0)
                    }
                    .buttonStyle(PressableButtonStyle())
                    
                    Spacer()
                }
                Spacer()
            }
            .padding(8)
            
            // Кнопка добавления в очередь (справа снизу)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        addToQueue()
                    } label: {
                        Image(systemName: "text.badge.plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(themeObserver.themedPrimaryColor)
                            .frame(width: 32, height: 32)
                            .background(themeObserver.contrastColor)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(8)
        }
        .appBackground(padding: 6)
        .scaleEffect(isPressed ? 1.05 : 1.0)
        .onTapGesture {
            playVideo()
        }
        .onLongPressGesture(minimumDuration: 0.2) {
            onLongPress()
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
    
    private func playVideo() {
        let track = createTrackFromVideo()
        queueService.playTrack(track)
    }
    
    private func addToQueue() {
        let track = createTrackFromVideo()
        queueService.addToWishlist(track)
    }
    
    private func createTrackFromVideo() -> Track {
        // Проверяем, есть ли уже такой трек
        if let existingTrack = TrackController.shared.tracks.first(where: { $0.remoteVideoId == video.id }) {
            return existingTrack
        }
        
        // Используем proxy endpoint для воспроизведения
        let baseURL = AppConfig.apiBaseURL
        let proxyURL = "\(baseURL)/api/videos/\(video.id)/stream/proxy"
        
        let track = Track(
            title: video.title,
            artist: video.subtitle,
            duration: video.duration,
            remoteVideoId: video.id,
            videoURL: proxyURL,
            thumbnailURL: video.imageURL,
            ownerUserId: video.userId
        )
        
        // Сохраняем трек в репозиторий
        let repository = TrackRepository()
        repository.saveTrack(track)
        TrackController.shared.tracks.append(track)
        
        return track
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
        
        // Здесь логика лайка
        print("Toggle like for: \(video.title)")
    }
}
