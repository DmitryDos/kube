//
//  SearchAuthorView.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI

struct SearchAuthorView: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    
    let author: AuthorResult
    let onLongPress: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Фоновое изображение автора или градиент
            ZStack {
                if let imageURL = author.imageURL, !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            LinearGradient(
                                colors: [
                                    themeObserver.contrastColor,
                                    themeObserver.contrastColor.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .overlay(
                                ProgressView()
                                    .tint(themeObserver.themedAccentColor)
                            )
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            LinearGradient(
                                colors: [
                                    themeObserver.contrastColor,
                                    themeObserver.contrastColor.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .overlay(
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.5))
                                    .font(.system(size: 50))
                            )
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    LinearGradient(
                        colors: [
                            themeObserver.contrastColor,
                            themeObserver.contrastColor.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.5))
                            .font(.system(size: 50))
                    )
                }
            }
            .frame(height: 140)
            .clipped()

            // Информация об авторе
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    // Аватар автора
                    AsyncImage(url: URL(string: author.imageURL ?? "")) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(themeObserver.contrastColor)
                                .overlay(
                                    ProgressView()
                                        .tint(themeObserver.themedAccentColor)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Circle()
                                .fill(themeObserver.contrastColor)
                                .overlay(
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(themeObserver.themedPrimaryColor)
                                        .font(.system(size: 30))
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(themeObserver.themedAccentColor, lineWidth: 2)
                    )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(author.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeObserver.darkColor)
                            .lineLimit(1)
                        
                        if !author.subtitle.isEmpty {
                            Text(author.subtitle)
                                .font(.system(size: 12))
                                .foregroundColor(themeObserver.darkColor.opacity(0.7))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    Label("\(author.videoCount)", systemImage: "play.rectangle.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeObserver.darkColor.opacity(0.8))
                    
                    Label("\(author.followerCount)", systemImage: "person.2.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeObserver.darkColor.opacity(0.8))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(themeObserver.backgroundGlassColor)
            .cornerRadius(8)
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .appBackground(padding: 6)
        .scaleEffect(isPressed ? 1.05 : 1.0)
        .onTapGesture {
            // Можно добавить быстрый просмотр или переход
        }
        .onLongPressGesture(minimumDuration: 0.2) {
            onLongPress()
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
}
