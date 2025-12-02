//
//  SharedPlayerView.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI
import AVKit

/// Общий компонент плеера для переиспользования в HorizontalPlayerView и FullScreenVideoModal
struct SharedPlayerView: View {
    @ObservedObject private var audio = AudioPlayerService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    
    var body: some View {
        Group {
            if let track = audio.trackInfo.track {
                let contentType = track.contentType?.lowercased() ?? ""
                if contentType == "audio" {
                    // Для аудио показываем обложку (fit для горизонтального)
                    AsyncTrackImage(
                        imageURL: track.imageURL,
                        cornerRadius: 0,
                        imageContentMode: .fit,
                        showBackground: false,
                        canOpenModal: false
                    )
                    .clipped()
                } else {
                    // Для видео показываем видео плеер
                    AVPlayerViewControllerRepresented(
                        player: audio.player,
                        isPlaying: $audio.trackInfo.isPlaying,
                        showsPlaybackControls: false
                    )
                }
            } else {
                Rectangle()
                    .fill(themeObserver.darkColor)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 50))
                            .foregroundColor(themeObserver.accentColor)
                    )
            }
        }
    }
}

