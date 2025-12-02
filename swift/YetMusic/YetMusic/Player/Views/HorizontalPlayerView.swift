import SwiftUI
import AVKit

struct HorizontalPlayerView: View {
    @ObservedObject private var audio = AudioPlayerService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @ObservedObject private var queueService = QueueService.shared
    @ObservedObject private var uiState = UIStateService.shared
    @Environment(\.isLandscape) private var isLandscape
    @StateObject private var controlsSubModalProvider = SubModalProvider()
    
    var body: some View {
        ZStack {
            themeObserver.blackColor.ignoresSafeArea()

            playerView
                .ignoresSafeArea()
                .onTapGesture {
                    // Переключаем видимость контролов по клику на видео
                    if controlsSubModalProvider.modal != nil {
                        controlsSubModalProvider.dismiss()
                    } else {
                        controlsSubModalProvider.show(
                            PlayerControlsModal(controlsSubModalProvider: controlsSubModalProvider),
                            onClose: nil,
                            requiresBackground: false
                        )
                    }
                }
        }
        .withSubModalProvider(controlsSubModalProvider)
        .statusBar(hidden: true)
        .onAppear { 
            uiState.isFullPlayerVisible = true
            // Показываем контроллы при открытии
            controlsSubModalProvider.show(
                PlayerControlsModal(controlsSubModalProvider: controlsSubModalProvider),
                onClose: nil,
                requiresBackground: false
            )
        }
        .onDisappear {
            uiState.isFullPlayerVisible = false
        }
    }

    private var playerView: some View {
        SharedPlayerView()
    }
}
