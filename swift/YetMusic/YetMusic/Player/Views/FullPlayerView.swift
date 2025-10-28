import SwiftUI
import AVKit

struct FullPlayerView: View {
    @ObservedObject private var audio = AudioPlayerService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Environment(\.isLandscape) private var isLandscape
    @State private var showControls = true
    @State private var hideTimer: Timer?
    @State private var showingShareSheet = false
    
    let queueService = QueueService.shared

    var body: some View {
        Group {
            if isLandscape { landscape } else { portrait }
        }
        .onAppear {
            restartHideTimer()
        }
        .onDisappear {
            hideTimer?.invalidate()
        }
    }

    private var portrait: some View {
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
                        
                        Text(audio.trackInfo.track?.artist ?? "Unknown Artist")
                            .font(.title3)
                            .foregroundColor(themeObserver.textColor)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
                    .padding(.bottom, 20)
                    
                    playerView
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

    // MARK: landscape
    private var landscape: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            playerView.ignoresSafeArea()

            if showControls {
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 10) {
                        progressLandscape

                        ZStack(alignment: .trailing) {
                            controls.foregroundColor(.white)
                                .padding(.top, -30)
                                .padding(.bottom, -10)
                            
                            ActionButtonsPanel(
                                onShare: {
                                    showingShareSheet = true
                                },
                                currentTrack: queueService.getCurrentTrack()
                            )
                            .padding(.trailing, 0)
                            .offset(x: 172, y: -26)
                        }
                        .frame(height: 50)
                        .padding(.horizontal, 40)
                    }
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.35))
                }
                .transition(.opacity)
            }
        }
        .statusBar(hidden: true)
        .onTapGesture { toggleControls() }
    }

    // MARK: playerView
    private var playerView: some View {
        Group {
            if audio.trackInfo.track != nil {
                AVPlayerViewControllerRepresented(
                    player: audio.player,
                    isPlaying: $audio.trackInfo.isPlaying,
                    showsPlaybackControls: false
                )
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
        .cornerRadius(14)
    }

    // MARK: progress
    private var progress: some View {
        VStack(spacing: 3) {
            Slider(
                        value: Binding(
                            get: { audio.trackInfo.progress },
                            set: {
                                audio.seek(to: $0)
                                restartHideTimer()
                            }
                        ),
                        in: 0...1,
                        onEditingChanged: { editing in
                            if editing {
                                audio.startSeeking()
                            } else {
                                audio.seek(to: audio.trackInfo.progress)
                                audio.endSeeking()
                                restartHideTimer()
                            }
                        }
                    )
            .tint(themeObserver.darkColor)
            .padding(.horizontal, 23)

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
            .foregroundColor(themeObserver.darkColor)
            .padding(.horizontal, 10)
        }
    }

    private var progressLandscape: some View {
        VStack(spacing: 4) {
            Slider(
                        value: Binding(
                            get: { audio.trackInfo.progress },
                            set: {
                                audio.seek(to: $0)
                                restartHideTimer()
                            }
                        ),
                        in: 0...1,
                        onEditingChanged: { editing in
                            if editing {
                                audio.startSeeking()
                            } else {
                                audio.seek(to: audio.trackInfo.progress)
                                audio.endSeeking()
                                restartHideTimer()
                            }
                        }
                    )
            .tint(themeObserver.darkTextColor)
                .padding(.horizontal, 60)
            HStack {
                Text(format(audio.trackInfo.currentTime))
                Spacer()
                Text(format(audio.trackInfo.duration))
            }
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(themeObserver.darkTextColor)
            .padding(.horizontal, 60)
        }
    }

    // MARK: controls
    private var controls: some View {
        HStack(spacing: 36) {
            Button { audio.playPrevious() } label: {
                Image(systemName: "backward.end.fill")
            }
            .buttonStyle(ScaleButtonStyle())
            .offset(y: isLandscape ? 0 : 16)
            
            Button { audio.seekBackward(seconds: 10) } label: {
                Image(systemName: "gobackward.10")
            }
            .buttonStyle(ScaleButtonStyle())
            .offset(y: isLandscape ? 0 : -16)
            
            Button {
                audio.trackInfo.isPlaying ? audio.pause() : audio.play()
            } label: {
                Image(systemName: audio.trackInfo.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 60))
            }
            .buttonStyle(ScaleButtonStyle())
            .offset(y: isLandscape ? 0 : -16)
            
            Button { audio.seekForward(seconds: 10) } label: {
                Image(systemName: "goforward.10")
            }
            .buttonStyle(ScaleButtonStyle())
            .offset(y: isLandscape ? 0 : -16)
            
            Button { audio.playNext() } label: {
                Image(systemName: "forward.end.fill")
            }
            .buttonStyle(ScaleButtonStyle())
            .offset(y: isLandscape ? 0 : 16)
        }
        .font(.title2)
        .foregroundColor(isLandscape ? themeObserver.lightGlassColor : themeObserver.primaryGlassColor)
    }

    // MARK: helpers
    private func toggleControls() {
        withAnimation { showControls.toggle() }
        if showControls { restartHideTimer() } else { hideTimer?.invalidate() }
    }

    private func restartHideTimer() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in
            withAnimation { showControls = false }
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


struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
