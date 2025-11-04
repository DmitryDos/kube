//
//  AsyncTrackImage.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 20.10.2025.
//

import SwiftUI
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
        if let thumbnailURLString = track.thumbnailURL {
            var fullURLString = thumbnailURLString
            
            // Если URL относительный, добавляем baseURL
            if thumbnailURLString.hasPrefix("/") {
                fullURLString = VideoService.shared.baseURL + thumbnailURLString
            }
            
            if let thumbnailURL = URL(string: fullURLString) {
                loadRemoteThumbnail(from: thumbnailURL)
            } else {
                print("[AsyncTrackImage] Invalid thumbnail URL: \(thumbnailURLString)")
                isLoading = false
            }
        } else {
            // Если нет thumbnail - показываем иконку
            isLoading = false
        }
    }
    
    private func loadRemoteThumbnail(from url: URL) {
        print("[AsyncTrackImage] Loading thumbnail from: \(url.absoluteString)")
        downloadTask = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("[AsyncTrackImage] Error loading thumbnail: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("[AsyncTrackImage] Thumbnail response status: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        print("[AsyncTrackImage] Non-200 status code")
                        return
                    }
                }
                
                if let data = data, let image = UIImage(data: data) {
                    print("[AsyncTrackImage] Successfully loaded thumbnail, size: \(data.count) bytes")
                    self.image = image
                } else {
                    print("[AsyncTrackImage] Failed to create image from data")
                }
            }
        }
        downloadTask?.resume()
    }
    
    private func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        isLoading = false
    }
}
