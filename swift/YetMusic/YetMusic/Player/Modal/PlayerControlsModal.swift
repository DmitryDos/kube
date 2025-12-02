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

    var showCloseButton: Bool = false
    var controlsSubModalProvider: SubModalProvider?

    private var menuButtons: [ActionButton] {
        [
            ActionButton(
                title: "Тема",
                icon: themeObs.isDarkTheme ? "sun.max.fill" : "moon.fill",
                color: themeObs.themedAccentColor
            ) { withAnimation { themeObs.toggleTheme() } },
            ActionButton(
                title: "Профиль",
                icon: "person.crop.circle",
                color: themeObs.themedAccentColor
            ) { currentPage.wrappedValue = 3 },
            ActionButton(
                title: "Добавить треки",
                icon: "arrow.down.circle.fill",
                color: themeObs.themedAccentColor
            ) { ModalProvider.shared.showModalContainer(AddTrackModal()) },
            ActionButton(
                title: "Загрузка",
                icon: "tray.full",
                color: themeObs.themedAccentColor
            ) { ModalProvider.shared.show(VideoLoaderModal()) },
        ]
    }

    @AppStorage("playerSearchVisible") private var isSearchVisible = true
    @State private var isMenuOpen = false
    
    private var likeIconName: String {
        if let track = audio.trackInfo.track, playlistService.isTrackLiked(track) {
            return "heart.fill"
        }
        return "heart"
    }

    var body: some View {
        let track = audio.trackInfo.track
        let hasQueue = !queueService.wishlistQueue.isEmpty || queueService.currentQueue.count > 1
        
        GeometryReader { geometry in
            // Учитываем видимость поиска (safeArea уже учитывается в CompactSearchView)
            let searchWidth: CGFloat = isSearchVisible ? 250 : 1
            let searchSpacing: CGFloat = isSearchVisible ? 8 : 0
            let leadingPadding = searchWidth + searchSpacing + (isSearchVisible ? 0 : 24)
            let trailingPadding: CGFloat = 0
            
            ZStack {
                VStack(spacing: 12) {
                    // Верхняя панель с информацией
                    HStack(spacing: 8) {
                        if showCloseButton {
                            Button {
                                ModalProvider.shared.dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(audio.trackInfo.track?.title ?? "No Track")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeObserver.textColor)
                                .lineLimit(1)
                            
                            Text(audio.trackInfo.track?.desc ?? "Empty Description")
                                .font(.system(size: 12))
                                .foregroundColor(themeObserver.textColor.opacity(0.8))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 6) {
                            Button(action: {
                                if let track = track {
                                    playlistService.toggleLike(track: track)
                                }
                            }) {
                                Image(systemName: likeIconName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(track != nil && playlistService.isTrackLiked(track!) ? themeObserver.likeColor : themeObserver.themedAccentColor)
                                    .frame(width: 36, height: 36)
                            }
                            .disabled(track == nil)
                            
                            Button(action: {
                                showingShareSheet = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(themeObserver.textColor)
                                    .frame(width: 36, height: 36)
                            }
                            
                            if !isMenuOpen {
                                Button(action: {
                                    isMenuOpen = true
                                    if let controlsSubModalProvider = controlsSubModalProvider {
                                        controlsSubModalProvider.show(
                                            FloatingActionMenuModal(buttons: menuButtons),
                                            onClose: {
                                                isMenuOpen = false
                                            },
                                            requiresBackground: false
                                        )
                                    } else {
                                        ModalProvider.shared.show(
                                            FloatingActionMenuModal(buttons: menuButtons),
                                            onClose: {
                                                isMenuOpen = false
                                            },
                                            requiresBackground: false
                                        )
                                    }
                                }) {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(themeObserver.textColor)
                                        .frame(width: 36, height: 36)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(themeObserver.backgroundGlassColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                themeObserver.whiteColor.opacity(themeObserver.isDarkTheme ? 0.3 : 0.4),
                                lineWidth: 1
                            )
                    )
                    .overlay(
                        ModalMarkerView()
                            .allowsHitTesting(false)
                    )
                    .padding(.leading, leadingPadding)
                    .padding(.trailing, trailingPadding)
                    .padding(.top, 8)
                
                    Spacer()
                    
                    // Средняя панель с контролами
                    HStack(alignment: .center, spacing: 12) {
                        // Центральная панель с кнопками управления
                        VStack(spacing: 12) {
                            HStack(spacing: 20) {
                                Button { audio.seekBackward(seconds: 10) } label: {
                                Image(systemName: "gobackward.10")
                                    .font(.system(size: 20))
                                    .foregroundColor(themeObserver.textColor)
                                    .frame(width: 44, height: 44)
                            }
                            
                            Button { audio.playPrevious() } label: {
                                Image(systemName: "backward.end.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(themeObserver.textColor)
                                    .frame(width: 44, height: 44)
                            }
                            .disabled(queueService.currentIndex <= 0)
                            .opacity(queueService.currentIndex <= 0 ? 0.5 : 1.0)
                            
                            Button {
                                audio.trackInfo.isPlaying ? audio.pause() : audio.play()
                            } label: {
                                Image(systemName: audio.trackInfo.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(themeObserver.themedAccentColor)
                            }
                            
                            Button { audio.playNext() } label: {
                                Image(systemName: "forward.end.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(themeObserver.textColor)
                                    .frame(width: 44, height: 44)
                            }
                            .disabled(queueService.currentIndex >= queueService.currentQueue.count - 1 && queueService.wishlistQueue.isEmpty)
                            .opacity((queueService.currentIndex >= queueService.currentQueue.count - 1 && queueService.wishlistQueue.isEmpty) ? 0.5 : 1.0)
                            
                            Button { audio.seekForward(seconds: 10) } label: {
                                Image(systemName: "goforward.10")
                                    .font(.system(size: 20))
                                    .foregroundColor(themeObserver.textColor)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(themeObserver.backgroundGlassColor)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    themeObserver.whiteColor.opacity(themeObserver.isDarkTheme ? 0.3 : 0.4),
                                    lineWidth: 1
                                )
                        )
                    }
                    .padding(.leading, leadingPadding)
                    
                    // Кнопка очереди справа (если есть очередь)
                    if hasQueue {
                        Button {
                            if let controlsSubModalProvider = controlsSubModalProvider {
                                controlsSubModalProvider.show(
                                    QueueSideModal(),
                                    onClose: nil,
                                    requiresBackground: true
                                )
                            } else {
                                ModalProvider.shared.show(QueueSideModal())
                            }
                        } label: {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeObserver.themedAccentColor)
                        }
                        .frame(width: 22, height: 22)
                        .appBackground()
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    themeObserver.whiteColor.opacity(themeObserver.isDarkTheme ? 0.3 : 0.4),
                                    lineWidth: 1
                                )
                        )
                        .overlay(
                            ModalMarkerView()
                                .allowsHitTesting(false)
                        )
                    }
                    
                    if isSearchVisible {
                        Spacer()
                    }
                }

                    VStack(spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(themeObserver.textColor.opacity(0.25))
                                    .frame(height: 4)
                                Capsule()
                                    .fill(themeObserver.textColor.opacity(0.55))
                                    .frame(width: max(0, CGFloat(audio.trackInfo.bufferedProgress)) * geo.size.width, height: 4)
                                    .animation(.linear(duration: 0.1), value: audio.trackInfo.bufferedProgress)
                                
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
                                .tint(.clear)
                                .accentColor(themeObserver.textColor)
                            }
                        }
                        .frame(height: 44)
                        
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(themeObserver.backgroundGlassColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                themeObserver.whiteColor.opacity(themeObserver.isDarkTheme ? 0.3 : 0.4),
                                lineWidth: 1
                            )
                    )
                    .padding(.leading, leadingPadding)
                    .padding(.trailing, trailingPadding)
                    .overlay(
                        ModalMarkerView()
                            .allowsHitTesting(false)
                    )
                    .padding(.bottom, 8)
                }
                
                // Поиск слева
                HStack(spacing: 0) {
                    CompactSearchView()
                        .overlay(
                            ModalMarkerView()
                                .allowsHitTesting(false)
                        )
                    
                    Spacer()
                }
                .ignoresSafeArea(edges: .vertical)
            }
        }
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
