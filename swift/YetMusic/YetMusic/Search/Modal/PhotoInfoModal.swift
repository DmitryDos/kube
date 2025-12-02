//
//  PhotoInfoModal.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI

struct PhotoInfoModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let track: Track
    
    private var imageURL: URL? {
        return track.imageURL
    }
    
    var body: some View {
        ModalContainer(
            title: track.title.isEmpty ? "Фото" : track.title
        ) {
            VStack(spacing: 20) {
                // Фото на всю ширину - используем AsyncTrackImage для кэширования
                if let url = imageURL {
                    AsyncTrackImage(
                        imageURL: url,
                        cornerRadius: 0,
                        imageContentMode: .fit,
                        showBackground: false,
                        isPhoto: true,
                        canOpenModal: true,
                        track: track
                    )
                    .frame(maxWidth: .infinity)
                }
                
                // Информация о фото
                VStack(spacing: 16) {
                    if !track.desc.isEmpty {
                        TextFieldWithLabel(
                            title: "Описание",
                            placeholder: "",
                            text: .constant(track.desc),
                            onChange: {},
                            isEditable: false
                        )
                    }
                    
                    VStack(spacing: 8) {
                        if !track.desc.isEmpty {
                            DetailRow(title: "Автор", value: track.desc)
                        }
                    }
                    .padding()
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

