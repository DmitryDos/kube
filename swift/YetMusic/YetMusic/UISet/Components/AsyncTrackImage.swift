//
//  AsyncTrackImage.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 20.10.2025.
//

import SwiftUI
import AVFoundation
import UIKit

struct AsyncTrackImage: View {
    let track: Track
    let cornerRadius: CGFloat
    let width: CGFloat?
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var downloadTask: URLSessionDataTask?
    @ObservedObject private var themeObserver = ThemeObserver.shared

    init(track: Track, cornerRadius: CGFloat = 8, width: CGFloat? = nil) {
        self.track = track
        self.cornerRadius = cornerRadius
        self.width = width
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(themeObserver.contrastColor)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                Group {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: min(geometry.size.width, geometry.size.height) * 0.3))
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .cornerRadius(cornerRadius)
            .clipped()
        }
        .aspectRatio(16/9, contentMode: .fit)
        .frame(width: width)
        .onAppear {
            loadImage()
        }
        .onChange(of: track.id) { _ in
            cancelDownload()
            image = nil
            loadImage()
        }
        .onDisappear {
            cancelDownload()
        }
    }
    
    private func loadImage() {
        guard image == nil, !isLoading else { return }
        
        isLoading = true
        
        // Если есть thumbnail URL от сервера - загружаем его
        if let thumbnailURLString = track.thumbnailURL,
           let thumbnailURL = URL(string: thumbnailURLString) {
            loadRemoteThumbnail(from: thumbnailURL)
        }
        // Иначе генерируем из видео URL
        else if let videoURL = track.playableURL {
            generateThumbnail(from: videoURL)
        }
        // Если URL недоступен, но есть remote id — пробуем через proxy c JWT
        else if let videoID = track.remoteVideoId {
            let base = VideoService.shared.baseURL
            if let url = URL(string: base + "/api/videos/\(videoID)/stream/proxy"),
               let token = UserDefaults.standard.string(forKey: "authToken") {
                let headers = ["Authorization": "Bearer \(token)"]
                let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
                generateThumbnail(from: asset)
            } else {
                isLoading = false
            }
        }
        // Если нет URL для видео - показываем иконку
        else {
            isLoading = false
        }
    }
    
    private func loadRemoteThumbnail(from url: URL) {
        downloadTask = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let data = data, let image = UIImage(data: data) {
                    self.image = image
                } else {
                    // Если не удалось загрузить thumbnail, пробуем сгенерировать из видео
                    if let videoURL = self.track.playableURL {
                        self.generateThumbnail(from: videoURL)
                    }
                }
            }
        }
        downloadTask?.resume()
    }
    
    private func generateThumbnail(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnail = self.generateThumbnail(for: url)
            
            DispatchQueue.main.async {
                self.image = thumbnail
                self.isLoading = false
            }
        }
    }
    
    private func generateThumbnail(for url: URL) -> UIImage? {
        // Для удаленных видео создаем временный файл или используем AVAsset с URL
        if url.isFileURL {
            // Локальный файл
            let asset = AVAsset(url: url)
            return generateThumbnail(from: asset)
        } else {
            // Удаленный URL - создаем AVAsset с URL
            let asset = AVAsset(url: url)
            return generateThumbnail(from: asset)
        }
    }
    
    private func generateThumbnail(from asset: AVAsset) -> UIImage? {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        // Пробуем разные временные точки для лучшего thumbnail
        let timePoints = [CMTime(seconds: 0, preferredTimescale: 60),
                         CMTime(seconds: 5, preferredTimescale: 60),
                         CMTime(seconds: 10, preferredTimescale: 60)]
        
        for time in timePoints {
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                return UIImage(cgImage: cgImage)
            } catch {
                continue
            }
        }
        
        print("Не удалось сгенерировать thumbnail для трека: \(track.title)")
        return nil
    }
    
    private func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        isLoading = false
    }
}
