import SwiftUI
import AVKit

struct HorizontalPlayerView: View {
    @ObservedObject private var audio = AudioPlayerService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @State private var isModalOpen = false
    
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
