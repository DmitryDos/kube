import SwiftUI

struct PlayerControlsModal: View {
    @ObservedObject private var queueService = QueueService.shared
    @ObservedObject private var audio = AudioPlayerService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @State private var showingShareSheet = false
    @ObservedObject private var playlistService = PlaylistService.shared
    @Environment(\.currentPage) private var currentPage
    @ObservedObject private var themeObs = ThemeObserver.shared
    @Environment(\.isLandscape) private var isLandscape
    @ObservedObject private var uiState = UIStateService.shared

    private var menuButtons: [ActionButton] {
        [
            ActionButton(
                title: "Тема",
                icon: themeObs.isDarkTheme ? "sun.max.fill" : "moon.fill",
                color: .orange
            ) { withAnimation { themeObs.toggleTheme() } },
            ActionButton(
                title: "Профиль",
                icon: "person.crop.circle",
                color: .blue
            ) { currentPage.wrappedValue = 3 },
            ActionButton(
                title: "Добавить треки",
                icon: "arrow.down.circle.fill",
                color: .yellow
            ) { ModalProvider.shared.show(AddTrackModal()) },
            ActionButton(
                title: "Загрузка",
                icon: "tray.full",
                color: .pink
            ) { ModalProvider.shared.show(VideoLoaderModal()) },
        ]
    }

    var body: some View {
        let track = audio.trackInfo.track
        ZStack {
            VStack {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        GlassBlock {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(audio.trackInfo.track?.title ?? "No Track")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(themeObserver.textColor)
                                        .lineLimit(1)
                                    
                                    Text(audio.trackInfo.track?.artist ?? "Unknown Artist")
                                        .font(.system(size: 12))
                                        .foregroundColor(themeObserver.textColor.opacity(0.8))
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                            }
                            .frame(width: 260, height: 30)
                        }
                        
                        GlassBlock {
                            Button(action: {
                                if let track = track {
                                    PreloadService.shared.startPreloading(for: track)
                                }
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18))
                                    .foregroundColor(themeObserver.textColor)
                                    .frame(width: 30, height: 30)
                            }
                        }
                        
                        Spacer()

                        if !uiState.isFloatingMenuOpen {
                            GlassBlock {
                                Button(action: {
                                    UIStateService.shared.isFloatingMenuOpen = true
                                    ModalProvider.shared.show(
                                        FloatingActionMenuModal(buttons: menuButtons),
                                        onClose: {
                                            UIStateService.shared.isFloatingMenuOpen = false
                                        }
                                    )
                                }) {
                                    ZStack {
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 26))
                                            .foregroundColor(themeObserver.textColor)
                                    }
                                }
                                .frame(width: 24, height: 24)
                            }
                        }
                    }
                    
                    HStack(spacing: 6) {
                        GlassBlock {
                            Button(action: {
                                if let track = audio.trackInfo.track {
                                    playlistService.toggleLike(track: track)
                                }
                            }) {
                                Image(systemName: likeIconName)
                                    .font(.system(size: 18))
                                    .foregroundColor(themeObserver.textColor)
                                    .frame(width: 30, height: 30)
                            }
                        }
                        
                        GlassBlock {
                            Button(action: {
                                showingShareSheet = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18))
                                    .foregroundColor(themeObserver.textColor)
                                    .frame(width: 30, height: 30)
                            }
                        }

                        Spacer()
                    }
                }
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    GlassBlock {
                        Button(action: {
                            ModalProvider.shared.replace(
                                QueueSideModal(),
                                onClose: {
                                    ModalProvider.shared.replace(
                                        PlayerControlsModal(),
                                    )
                                }
                            )
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "eye")
                                    .font(.system(size: 18))
                                    .foregroundColor(themeObserver.textColor)
                                
                                Text("Очередь")
                                    .font(.system(size: 11))
                                    .foregroundColor(themeObserver.textColor)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(width: 150, height: 45)
                        }
                    }
                    
                    Spacer()
                    
                    GlassBlock {
                        VStack(spacing: 0) {
                            VStack(spacing: 6) {
                                GeometryReader { geo in
                                    let horizontalPadding: CGFloat = 4
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(themeObserver.textColor.opacity(0.25))
                                            .frame(height: 4)
                                        Capsule()
                                            .fill(themeObserver.textColor.opacity(0.55))
                                            .frame(width: max(0, CGFloat(audio.trackInfo.bufferedProgress)) * max(0, geo.size.width - horizontalPadding * 2), height: 4)
                                            .animation(.linear(duration: 0.1), value: audio.trackInfo.bufferedProgress)
                                    }
                                    .padding(.horizontal, horizontalPadding)
                                    .frame(height: 32)
                                    
                                    Slider(
                                        value: Binding(
                                            get: { max(0, min(1, audio.trackInfo.progress)) },
                                            set: { audio.seek(to: max(0, min(1, $0))) }
                                        ),
                                        in: 0...1,
                                        onEditingChanged: { editing in
                                            if editing { audio.startSeeking() } else { audio.seek(to: audio.trackInfo.progress); audio.endSeeking() }
                                        }
                                    )
                                    .tint(themeObserver.textColor)
                                    .padding(.horizontal, horizontalPadding)
                                }
                                .frame(height: 24)
                                
                                HStack {
                                    Text(format(audio.trackInfo.currentTime))
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(themeObserver.textColor)
                                    
                                    Spacer()
                                    
                                    Text(format(audio.trackInfo.duration))
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(themeObserver.textColor)
                                }
                            }

                            HStack(spacing: 25) {
                                Button { audio.playPrevious() } label: {
                                    Image(systemName: "backward.end.fill")
                                        .font(.system(size: 30))
                                }
                                
                                Button { audio.seekBackward(seconds: 10) } label: {
                                    Image(systemName: "gobackward.10")
                                        .font(.system(size: 22))
                                }
                                
                                Button {
                                    audio.trackInfo.isPlaying ? audio.pause() : audio.play()
                                } label: {
                                    Image(systemName: audio.trackInfo.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 56))
                                }
                                
                                Button { audio.seekForward(seconds: 10) } label: {
                                    Image(systemName: "goforward.10")
                                        .font(.system(size: 22))
                                }
                                
                                Button { audio.playNext() } label: {
                                    Image(systemName: "forward.end.fill")
                                        .font(.system(size: 30))
                                }
                            }
                            .foregroundColor(themeObserver.textColor)
                        }
                        .frame(width: 300, height: 100)
                    }
                    
                    Spacer()
                    
                    GlassBlock {
                        Button(action: {
                            ModalProvider.shared.replace(
                                SearchDockModal(),
                                    onClose: { ModalProvider.shared.replace(
                                        PlayerControlsModal(),
                                    )
                                }
                            )
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 18))
                                    .foregroundColor(themeObserver.textColor)
                                
                                Text("Смотрите также")
                                    .font(.system(size: 11))
                                    .foregroundColor(themeObserver.textColor)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(width: 150, height: 45)
                        }
                    }
                }
                .padding(.top, 12)
            }
        }
        .padding(16)
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

private extension PlayerControlsModal {
    var likeIconName: String {
        if let track = audio.trackInfo.track, playlistService.isTrackLiked(track) {
            return "heart.fill"
        }
        return "heart"
    }
}

struct GlassBlock<Content: View>: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .appBackground()
            .overlay(ModalMarkerView().allowsHitTesting(false))
    }
}
