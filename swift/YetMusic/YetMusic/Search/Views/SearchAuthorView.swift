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
                            Image(systemName: "person.circle")
                                .foregroundColor(themeObserver.themedPrimaryColor)
                                .font(.system(size: 40))
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(themeObserver.themedAccentColor, lineWidth: 2)
            )

            // Информация об авторе
            VStack(alignment: .leading, spacing: 4) {
                Text(author.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(themeObserver.themedPrimaryColor)
                    .lineLimit(1)
                
                Text(author.subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.8))
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    Label("\(author.videoCount)", systemImage: "play.rectangle")
                        .font(.system(size: 12))
                    
                    Label("\(author.followerCount)", systemImage: "person.2")
                        .font(.system(size: 12))
                }
                .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.7))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeObserver.backgroundGlassColor)
            .cornerRadius(12)
            .padding(.top, 40)
        }
        .appBackground(padding: 6)
        .scaleEffect(isPressed ? 1.05 : 1.0)
        .onTapGesture {
            openAuthorProfile()
        }
        .onLongPressGesture(minimumDuration: 0.2) {
            onLongPress()
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
    
    private func openAuthorProfile() {
        print("Open author profile: \(author.title)")
    }
}
