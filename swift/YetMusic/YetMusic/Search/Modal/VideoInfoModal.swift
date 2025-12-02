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
    
    private var isOwner: Bool {
        guard AuthService.shared.isAuthenticated,
              let ownerId = video.ownerUserId,
              let currentUserId = AuthService.shared.currentUser?.id else {
            return false
        }
        return ownerId == currentUserId
    }
    
    var body: some View {
        ModalContainer(
            title: "Информация о видео",
            leftButton: isOwner ? AnyView(
                Button {
                    ModalProvider.shared.showModalContainer(EditVideoModal(track: video, isReadOnly: false))
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(themeObserver.themedAccentColor)
                }
            ) : nil,
            bottomButton: nil
        ) {
            VStack(spacing: 20) {
                // Кнопка редактирования выше обложки
                if isOwner {
                    Button {
                        ModalProvider.shared.showModalContainer(EditVideoModal(track: video, isReadOnly: false))
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                                .font(.system(size: 16, weight: .medium))
                            Text("Редактировать видео")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(themeObserver.themedAccentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(themeObserver.backgroundGlassColor)
                        .cornerRadius(12)
                    }
                }
                
                AsyncTrackImage(
                    track: video,
                    imageContentMode: .fit,
                    canOpenModal: true
                )
                .frame(maxWidth: .infinity)

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
    
    @State private var searchText: String = ""
    @State private var isLoadingVideos = false
    @State private var authorVideos: [Track] = []
    
    var body: some View {
        ModalContainer(
            title: author.title,
            leftButton: nil,
            bottomButton: nil
        ) {
            VStack(spacing: 20) {
                // Информация об авторе
                VStack(spacing: 16) {
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
                                        .font(.system(size: 50))
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(themeObserver.themedAccentColor, lineWidth: 2)
                    )
                    
                    if !author.subtitle.isEmpty {
                        Text(author.subtitle)
                            .font(.body)
                            .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    HStack(spacing: 40) {
                        VStack(spacing: 4) {
                            Text("\(author.videoCount)")
                                .font(.title2.weight(.bold))
                                .foregroundColor(themeObserver.themedAccentColor)
                            Text("Видео")
                                .font(.caption)
                                .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.7))
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(author.followerCount)")
                                .font(.title2.weight(.bold))
                                .foregroundColor(themeObserver.themedAccentColor)
                            Text("Подписчиков")
                                .font(.caption)
                                .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.7))
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                
                Divider()
                    .background(themeObserver.contrastColor)
                
                // Поиск
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.6))
                    
                    ZStack(alignment: .leading) {
                        if searchText.isEmpty {
                            Text("Поиск видео...")
                                .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.6))
                        }
                        TextField("", text: $searchText)
                        .foregroundColor(themeObserver.themedPrimaryColor)
                        .onSubmit {
                            loadAuthorVideos()
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            loadAuthorVideos()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.6))
                        }
                    }
                }
                .padding()
                .background(themeObserver.contrastColor)
                .cornerRadius(12)
                
                // Список видео
                if isLoadingVideos {
                    ProgressView()
                        .tint(themeObserver.themedAccentColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if filteredVideos.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 40))
                            .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.5))
                        Text("Видео не найдены")
                            .font(.body)
                            .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredVideos, id: \.id) { track in
                                AuthorVideoRow(track: track)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            loadAuthorVideos()
        }
    }
    
    private var filteredVideos: [Track] {
        if searchText.isEmpty {
            return authorVideos
        }
        return authorVideos.filter { track in
            track.title.localizedCaseInsensitiveContains(searchText) ||
            track.desc.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func loadAuthorVideos() {
        isLoadingVideos = true
        
        // Конвертируем author.id в UUID для фильтрации
        let authorUUID: UUID?
        if let uuid = UUID(uuidString: author.id) {
            authorUUID = uuid
        } else {
            // Если не UUID, используем computed property
            authorUUID = author.uuid
        }
        
        guard let userId = authorUUID else {
            isLoadingVideos = false
            return
        }
        
        // Используем SearchService для загрузки видео автора
        SearchService.shared.searchWithPagination(
            query: searchText.isEmpty ? nil : searchText,
            filter: .videos,
            page: 1,
            pageSize: 50,
            userId: userId,
            trackIds: nil
        ) { _, videos, _ in
            DispatchQueue.main.async {
                self.authorVideos = videos
                self.isLoadingVideos = false
            }
        }
    }
}

struct AuthorVideoRow: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @ObservedObject private var queueService = QueueService.shared
    
    let track: Track
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncTrackImage(track: track, canOpenModal: true)
                .frame(width: 80, height: 80)
                .aspectRatio(1.0, contentMode: .fill)
                .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeObserver.themedPrimaryColor)
                    .lineLimit(2)
                
                if !track.desc.isEmpty {
                    Text(track.desc)
                        .font(.system(size: 12))
                        .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.7))
                        .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    if track.duration > 0 {
                        Label(formatDuration(track.duration), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.6))
                    }
                    
                    if let fileSize = track.fileSize {
                        Label(formatFileSize(fileSize), systemImage: "doc")
                            .font(.caption)
                            .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.6))
                    }
                }
            }
            
            Spacer()
            
            Button {
                queueService.playTrack(track)
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(themeObserver.themedAccentColor)
            }
        }
        .padding()
        .background(themeObserver.contrastColor)
        .cornerRadius(12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

