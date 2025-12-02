//
//  FullScreenVideoModal.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI
import AVKit

struct FullScreenVideoModal: View {
    @ObservedObject private var audio = AudioPlayerService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @ObservedObject private var queueService = QueueService.shared
    @StateObject private var orientation = OrientationObserver()
    @StateObject private var controlsSubModalProvider = SubModalProvider()
    @State private var isDismissing = false
    @State private var hasRotated = false
    
    let track: Track
    
    var body: some View {
        ZStack {
            themeObserver.blackColor.ignoresSafeArea()
            
            // Видео плеер (переиспользуем общий компонент)
            SharedPlayerView()
                .ignoresSafeArea()
                .onTapGesture {
                    // Переключаем видимость контролов по клику на видео
                    if controlsSubModalProvider.modal != nil {
                        controlsSubModalProvider.dismiss()
                    } else {
                        controlsSubModalProvider.show(
                            PlayerControlsModal(showCloseButton: true, controlsSubModalProvider: controlsSubModalProvider),
                            onClose: nil,
                            requiresBackground: false
                        )
                    }
                }
        }
        .withSubModalProvider(controlsSubModalProvider)
        .statusBar(hidden: true)
        .onAppear {
            // Загружаем трек если еще не загружен
            if audio.trackInfo.track?.id != track.id {
                queueService.playTrack(track)
            }
            
            // Строго переключаем в горизонтальный режим сразу
            if !hasRotated {
                hasRotated = true
                // Используем задержку для гарантии, что view уже появился
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    OrientationLock.rotateToLandscape()
                }
            }
            
            // Показываем контроллы при открытии
            controlsSubModalProvider.show(
                PlayerControlsModal(showCloseButton: true, controlsSubModalProvider: controlsSubModalProvider),
                onClose: nil,
                requiresBackground: false
            )
        }
        .onChange(of: orientation.isLandscape) { isLandscape in
            // Закрываем модалку при повороте из горизонтального режима
            // Но только если мы еще не закрываемся и это не первый поворот
            if !isLandscape && !isDismissing && hasRotated {
                // Проверяем, что устройство действительно в вертикальном режиме
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    let currentOrientation = scene.interfaceOrientation
                    if currentOrientation == .portrait || currentOrientation == .portraitUpsideDown {
                        isDismissing = true
                        // Закрываем модалку с небольшой задержкой для стабильности
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            ModalProvider.shared.dismiss()
                        }
                    }
                }
            }
        }
    }
}

