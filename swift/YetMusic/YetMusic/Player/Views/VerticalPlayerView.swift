//
//  VerticalPlayerView.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 30.10.2025.
//


import SwiftUI
import AVKit

struct VerticalPlayerView: View {
    @ObservedObject private var audio = AudioPlayerService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @State private var showingShareSheet = false
    
    let queueService = QueueService.shared

    var body: some View {
        GeometryReader { geo in
            let windowHeight: CGFloat = geo.size.height
            let windowWidth: CGFloat = geo.size.width
            
            ZStack {
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Text(audio.trackInfo.track?.title ?? "No Track")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeObserver.themedAccentColor)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                        
                        Text(audio.trackInfo.track?.desc ?? "Empty Description")
                            .font(.title3)
                            .foregroundColor(themeObserver.textColor)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
                    .padding(.bottom, 20)
                    
                    ZStack {
                        playerView
                        if audio.trackInfo.isBuffering {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.4)
                        }
                    }
                    .frame(width: geo.size.width - 48,
                           height: (geo.size.width - 42) * 9/16)
                    .appBackground()
                    
                    progress
                        .padding(.top, 6)
                        .padding(.bottom, 8)

                    ZStack(alignment: .trailing) {
                        controls
                            .padding(.bottom, 20)
                        
                        ActionButtonsPanel(
                            onShare: {
                                showingShareSheet = true
                            },
                            currentTrack: queueService.getCurrentTrack()
                        )
                        .offset(y: 56)
                    }
                    .frame(height: 50)
                    
                    Spacer(minLength: 0)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .sheet(isPresented: $showingShareSheet) {
                    if let track = queueService.getCurrentTrack() {
                        ShareSheet(activityItems: [track.playableURL])
                    }
                }
            }
        }
    }

    private var playerView: some View {
        Group {
            if let track = audio.trackInfo.track {
                let contentType = track.contentType?.lowercased() ?? ""
                if contentType == "audio" {
                    // Для аудио показываем обложку
                    AsyncTrackImage(
                        imageURL: track.imageURL,
                        cornerRadius: 10,
                        imageContentMode: .fill,
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
        .cornerRadius(10)
    }

    private var progress: some View {
        VStack(spacing: 3) {
            ZStack(alignment: .leading) {
                GeometryReader { geo in
                    let horizontalPadding: CGFloat = 23
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(themeObserver.darkColor.opacity(0.25))
                            .frame(height: 3)
                        Capsule()
                            .fill(themeObserver.darkColor.opacity(0.55))
                            .frame(width: max(0, CGFloat(audio.trackInfo.bufferedProgress)) * max(0, geo.size.width - horizontalPadding * 2), height: 3)
                            .animation(.linear(duration: 0.1), value: audio.trackInfo.bufferedProgress)
                    }
                    .padding(.horizontal, horizontalPadding)
                }
                .frame(height: 3)

                Slider(
                    value: Binding(
                        get: { max(0, min(1, audio.trackInfo.progress)) },
                        set: { audio.seek(to: max(0, min(1, $0))) }
                    ),
                    in: 0...1,
                    onEditingChanged: { editing in
                        if editing {
                            audio.startSeeking()
                        } else {
                            audio.seek(to: audio.trackInfo.progress)
                            audio.endSeeking()
                        }
                    }
                )
                .tint(themeObserver.darkColor)
                .padding(.horizontal, 23)
            }

            HStack {
                Text(format(audio.trackInfo.currentTime))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(themeObserver.backgroundGlassColor)
                    .cornerRadius(50)
                Spacer()
                Text(format(audio.trackInfo.duration))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(themeObserver.backgroundGlassColor)
                    .cornerRadius(50)
            }
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(themeObserver.textColor)
            .padding(.horizontal, 10)
        }
    }

    private var controls: some View {
        HStack(spacing: 36) {
            Button { audio.playPrevious() } label: {
                Image(systemName: "backward.end.fill")
            }
            .buttonStyle(ScaleButtonStyle())
            .offset(y: 16)
            
            Button { audio.seekBackward(seconds: 10) } label: {
                Image(systemName: "gobackward.10")
            }
            .buttonStyle(ScaleButtonStyle())
            .offset(y: -16)
            
            Button {
                audio.trackInfo.isPlaying ? audio.pause() : audio.play()
            } label: {
                Image(systemName: audio.trackInfo.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 60))
            }
            .buttonStyle(ScaleButtonStyle())
            .offset(y: -16)
            
            Button { audio.seekForward(seconds: 10) } label: {
                Image(systemName: "goforward.10")
            }
            .buttonStyle(ScaleButtonStyle())
            .offset(y: -16)
            
            Button { audio.playNext() } label: {
                Image(systemName: "forward.end.fill")
            }
            .buttonStyle(ScaleButtonStyle())
            .offset(y: 16)
        }
        .font(.title2)
        .foregroundColor(themeObserver.themedAccentColor)
    }

    private func format(_ t: TimeInterval) -> String {
        guard t.isFinite && !t.isNaN else {
            return "0:00"
        }

        let safeTime = max(0, t)
        let totalSeconds = Int(safeTime)
        
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        return String(format: "%d:%02d", minutes, seconds)
    }
}
