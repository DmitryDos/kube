//
//  SearchPhotoView.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI

struct SearchPhotoView: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    
    let track: Track
    let onLongPress: () -> Void
    
    private func showFullScreenPhoto() {
        ModalProvider.shared.show(PhotoViewModal(track: track, isReadOnly: true), requiresBackground: false, disableDismissOnTap: true)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Изображение - используем AsyncTrackImage для кэширования
            AsyncTrackImage(
                track: track,
                cornerRadius: 0,
                imageContentMode: .fit,
                canOpenModal: true
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(4/3, contentMode: .fit)
            .onLongPressGesture(minimumDuration: 0.2) {
                onLongPress()
            }
            
            // Информация о фото (если есть)
            if !track.title.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeObserver.textColor)
                        .lineLimit(2)
                    
                    if !track.desc.isEmpty {
                        Text(track.desc)
                            .font(.system(size: 11))
                            .foregroundColor(themeObserver.textColor.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

