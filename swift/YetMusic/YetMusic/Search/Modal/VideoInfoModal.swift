//
//  VideoInfoModal.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI

struct VideoInfoModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let video: Track
    
    var body: some View {
        ModalContainer(
            title: "Информация о видео",
            leftButton: nil,
            bottomButton: nil
        ) {
            VStack(spacing: 20) {
                AsyncTrackImage(track: video, width: .infinity)

                VStack(alignment: .leading, spacing: 16) {
                    Text(video.title)
                        .font(.title3.weight(.bold))
                        .foregroundColor(themeObserver.themedPrimaryColor)
                    
                    Text("Автор: \(video.ownerUserId)")
                        .font(.body)
                        .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.8))
                    
                    if !video.desc.isEmpty {
                        Text(video.desc)
                            .font(.body)
                            .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.7))
                    }
                    
                    VStack(spacing: 8) {
                        DetailRow(title: "Длительность", value: formatDuration(video.duration))
                        DetailRow(title: "Добавлено", value: formatDate(video.dateAdded))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}

struct AuthorInfoModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let author: AuthorResult
    
    var body: some View {
        ModalContainer(
            title: "Об авторе",
            leftButton: nil,
            bottomButton: nil
        ) {
            VStack(spacing: 20) {
                AsyncImage(url: URL(string: author.imageURL ?? "")) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    }
                }

                VStack(spacing: 16) {
                    Text(author.title)
                        .font(.title2.weight(.bold))
                        .foregroundColor(themeObserver.themedPrimaryColor)
                    
                    if !author.subtitle.isEmpty {
                        Text(author.subtitle)
                            .font(.body)
                            .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    HStack(spacing: 30) {
                        VStack {
                            Text("\(author.videoCount)")
                                .font(.title3.weight(.bold))
                                .foregroundColor(themeObserver.themedAccentColor)
                            Text("Видео")
                                .font(.caption)
                                .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.7))
                        }
                        
                        VStack {
                            Text("\(author.followerCount)")
                                .font(.title3.weight(.bold))
                                .foregroundColor(themeObserver.themedAccentColor)
                            Text("Подписчиков")
                                .font(.caption)
                                .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
}
