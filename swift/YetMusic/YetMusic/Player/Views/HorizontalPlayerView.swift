import SwiftUI
import AVKit

struct HorizontalPlayerView: View {
    @ObservedObject private var audio = AudioPlayerService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @State private var isModalOpen = false
    @ObservedObject private var uiState = UIStateService.shared
    @Environment(\.isLandscape) private var isLandscape
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            playerView
                .ignoresSafeArea()

            if !isModalOpen {
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        isModalOpen = true
                        ModalProvider.shared.show(
                            PlayerControlsModal(),
                            onClose: { isModalOpen = false },
                        )
                    }
            }
        }
        .statusBar(hidden: true)
        .onAppear { uiState.isFullPlayerVisible = true }
        .onDisappear {
            uiState.isFullPlayerVisible = false
            ModalProvider.shared.dismissAll()
        }
        .onChange(of: isLandscape) { _ in ModalProvider.shared.dismissAll() }
    }

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
    }
}
