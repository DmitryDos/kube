//
//  AsyncTrackImage.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 20.10.2025.
//

import SwiftUI
import UIKit

// Комбинированный кеш для изображений: сильный кеш для надежности + слабый для экономии памяти
private let imageCache = NSCache<NSString, UIImage>()
private let weakImageCache = NSMapTable<NSString, UIImage>(
    keyOptions: .strongMemory,
    valueOptions: .weakMemory
)

// Настройка кеша
private func setupImageCache() {
    imageCache.countLimit = 100 // Максимум 100 изображений в сильном кеше
    imageCache.totalCostLimit = 50 * 1024 * 1024 // 50 МБ
}

// Инициализация кеша при первом использовании
private let cacheSetupOnce: Void = {
    setupImageCache()
}()

struct AsyncTrackImage: View {
    let imageURL: URL?
    let cornerRadius: CGFloat
    let imageContentMode: ContentMode
    let showBackground: Bool
    let isPhoto: Bool
    let canOpenModal: Bool
    let track: Track?
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var downloadTask: URLSessionDataTask?
    @State private var retryCount = 0
    @State private var retryTask: DispatchWorkItem?
    @ObservedObject private var themeObserver = ThemeObserver.shared

    init(imageURL: URL?, cornerRadius: CGFloat = 8, imageContentMode: ContentMode = .fill, showBackground: Bool = true, isPhoto: Bool = false, canOpenModal: Bool = false, track: Track? = nil) {
        self.imageURL = imageURL
        self.cornerRadius = cornerRadius
        self.imageContentMode = imageContentMode
        self.showBackground = showBackground
        self.isPhoto = isPhoto
        self.canOpenModal = canOpenModal
        self.track = track
    }
    
    // Convenience initializer для обратной совместимости
    init(track: Track, cornerRadius: CGFloat = 8, imageContentMode: ContentMode = .fill, showBackground: Bool = true, canOpenModal: Bool = false) {
        self.imageURL = track.imageURL
        self.cornerRadius = cornerRadius
        self.imageContentMode = imageContentMode
        self.showBackground = showBackground
        self.isPhoto = track.contentType?.lowercased() == "image"
        self.canOpenModal = canOpenModal
        self.track = track
    }
    
    var body: some View {
            ZStack {
            if showBackground {
                Rectangle()
                    .fill(themeObserver.contrastColor)
            }
                
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                    .aspectRatio(contentMode: imageContentMode)
            } else if isLoading {
                if isPhoto {
                    // Красивая заглушка для фото с высотой 100px
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(themeObserver.themedAccentColor)
                        Spacer()
                    }
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .background(themeObserver.contrastColor.opacity(0.3))
                } else {
                    ProgressView()
                        .tint(themeObserver.themedAccentColor)
                }
                    } else {
                if isPhoto {
                    // Красивая заглушка для фото с высотой 100px
                    VStack {
                        Spacer()
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(themeObserver.textColor.opacity(0.5))
                        Spacer()
                    }
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .background(themeObserver.contrastColor.opacity(0.3))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(themeObserver.textColor.opacity(0.5))
                }
                    }
                }
            .cornerRadius(cornerRadius)
            .clipped()
            .contentShape(Rectangle())
            .allowsHitTesting(canOpenModal)
            .onTapGesture {
                if canOpenModal, let track = track {
                    // Проверяем, является ли пользователь владельцем трека
                    let isOwner: Bool = {
                        guard AuthService.shared.isAuthenticated,
                              let ownerId = track.ownerUserId,
                              let currentUserId = AuthService.shared.currentUser?.id else {
                            return false
                        }
                        return ownerId == currentUserId
                    }()
                    
                    // Если пользователь владелец - открываем в режиме редактирования, иначе только для просмотра
                    ModalProvider.shared.show(
                        PhotoViewModal(track: track, isReadOnly: !isOwner),
                        requiresBackground: false,
                        disableDismissOnTap: true
                    )
                }
            }
        .onAppear {
            _ = cacheSetupOnce // Инициализируем кеш при первом использовании
            loadImage()
        }
        .onChange(of: imageURL?.absoluteString) { _ in
            cancelDownload()
            cancelRetry()
            image = nil
            retryCount = 0
            loadImage()
        }
        .onDisappear {
            cancelDownload()
            cancelRetry()
        }
    }
    
    private func loadImage() {
        // Сначала проверяем локальное состояние
        if image != nil {
            return
        }
        
        guard let url = imageURL else {
            return
        }
        
        // Проверяем кеш ПЕРЕД установкой isLoading
        let key = url.absoluteString as NSString
        
        // Сначала проверяем сильный кеш (NSCache)
        if let cachedImage = imageCache.object(forKey: key) {
            self.image = cachedImage
            return
        }
        
        // Затем проверяем слабоссылочный кеш
        if let cachedImage = weakImageCache.object(forKey: key) {
            self.image = cachedImage
            // Восстанавливаем в сильном кеше для надежности
            imageCache.setObject(cachedImage, forKey: key)
            return
        }
        
        // Если нет в кеше и не загружаем - начинаем загрузку
        guard !isLoading else { return }
        
        isLoading = true
        loadRemoteThumbnail(from: url)
    }
    
    private func loadRemoteThumbnail(from url: URL) {
        print("[AsyncTrackImage] Loading thumbnail from: \(url.absoluteString) (attempt \(retryCount + 1))")
        
        // Для просмотра thumbnail авторизация не требуется
        var request = URLRequest(url: url)
        
        downloadTask = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                var shouldRetry = false
                
                if let error = error {
                    print("[AsyncTrackImage] Error loading thumbnail: \(error.localizedDescription)")
                    // Проверяем, стоит ли повторять попытку
                    let nsError = error as NSError
                    // Повторяем при сетевых ошибках или таймаутах
                    if nsError.domain == NSURLErrorDomain {
                        let code = nsError.code
                        shouldRetry = code == NSURLErrorTimedOut ||
                                     code == NSURLErrorNetworkConnectionLost ||
                                     code == NSURLErrorNotConnectedToInternet ||
                                     code == NSURLErrorCannotConnectToHost ||
                                     code == NSURLErrorDNSLookupFailed
                    }
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("[AsyncTrackImage] Thumbnail response status: \(httpResponse.statusCode)")
                    print("[AsyncTrackImage] Content-Type: \(httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "unknown")")
                    print("[AsyncTrackImage] URL: \(url.absoluteString)")
                    
                    if httpResponse.statusCode != 200 {
                        // Если это JSON ошибка, логируем её
                        if let data = data, let errorString = String(data: data, encoding: .utf8) {
                            print("[AsyncTrackImage] Error response: \(errorString.prefix(500))")
                        }
                        print("[AsyncTrackImage] Non-200 status code, skipping thumbnail")
                        // Повторяем при серверных ошибках (5xx) или временных ошибках (429, 503)
                        shouldRetry = httpResponse.statusCode >= 500 ||
                                     httpResponse.statusCode == 429 ||
                                     httpResponse.statusCode == 503
                    }
                }
                
                // Если произошла ошибка и нужно повторить
                if shouldRetry {
                    self.scheduleRetry(for: url)
                    return
                }
                
                // Если была ошибка и не нужно повторять - выходим
                if error != nil {
                    return
                }
                
                guard let data = data else {
                    print("[AsyncTrackImage] No data received")
                    // Если нет данных, но нет ошибки - возможно временная проблема
                    self.scheduleRetry(for: url)
                    return
                }
                
                print("[AsyncTrackImage] Received data size: \(data.count) bytes")
                print("[AsyncTrackImage] First 20 bytes: \(data.prefix(20).map { String(format: "%02x", $0) }.joined(separator: " "))")
                
                if let originalImage = UIImage(data: data) {
                    // Проверяем размеры изображения
                    let imageSize = originalImage.size
                    print("[AsyncTrackImage] Image size: \(imageSize.width)x\(imageSize.height)")
                    
                    // Если размеры некорректны, пытаемся исправить
                    if imageSize.width > 0 && imageSize.height > 0 && imageSize.width.isFinite && imageSize.height.isFinite {
                    print("[AsyncTrackImage] Successfully loaded thumbnail, size: \(data.count) bytes")
                    // Сбрасываем счетчик попыток и отменяем retry при успехе
                    self.retryCount = 0
                    self.cancelRetry()
                    
                    // Сохраняем в оба кеша
                    let key = url.absoluteString as NSString
                        imageCache.setObject(originalImage, forKey: key)
                        weakImageCache.setObject(originalImage, forKey: key)
                        self.image = originalImage
                    } else {
                        print("[AsyncTrackImage] Invalid image dimensions: \(imageSize.width)x\(imageSize.height)")
                        // Пытаемся пересоздать изображение с явным указанием scale
                        if let fixedImage = UIImage(data: data, scale: UIScreen.main.scale) {
                            let fixedSize = fixedImage.size
                            if fixedSize.width > 0 && fixedSize.height > 0 {
                                print("[AsyncTrackImage] Fixed image size: \(fixedSize.width)x\(fixedSize.height)")
                                let key = url.absoluteString as NSString
                                imageCache.setObject(fixedImage, forKey: key)
                                weakImageCache.setObject(fixedImage, forKey: key)
                                self.image = fixedImage
                            } else {
                                print("[AsyncTrackImage] Still invalid after fix, retrying")
                                self.scheduleRetry(for: url)
                            }
                        } else {
                            print("[AsyncTrackImage] Failed to fix image, retrying")
                            self.scheduleRetry(for: url)
                        }
                    }
                } else {
                    print("[AsyncTrackImage] Failed to create image from data (size: \(data.count) bytes)")
                    // Попробуем проверить, что это за данные
                    if let stringData = String(data: data, encoding: .utf8) {
                        print("[AsyncTrackImage] Data as string (first 200 chars): \(String(stringData.prefix(200)))")
                    }
                    // Если данные не являются изображением - возможно, это ошибка от сервера
                    // Повторяем попытку
                    self.scheduleRetry(for: url)
                }
            }
        }
        downloadTask?.resume()
    }
    
    private func scheduleRetry(for url: URL) {
        // Максимум 5 попыток
        guard retryCount < 5 else {
            print("[AsyncTrackImage] Max retry attempts reached for: \(url.absoluteString)")
            return
        }
        
        // Отменяем предыдущую задачу повторной попытки, если она есть
        cancelRetry()
        
        // Экспоненциальная задержка: 1s, 2s, 4s, 8s, 16s
        let delay = pow(2.0, Double(retryCount))
        let delaySeconds = min(delay, 16.0) // Максимум 16 секунд
        
        print("[AsyncTrackImage] Scheduling retry \(retryCount + 1) after \(delaySeconds) seconds")
        
        retryCount += 1
        
        let workItem = DispatchWorkItem {
            // Проверяем, что изображение все еще не загружено
            if self.image == nil {
                self.loadRemoteThumbnail(from: url)
            }
        }
        
        retryTask = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds, execute: workItem)
    }
    
    private func cancelRetry() {
        retryTask?.cancel()
        retryTask = nil
    }
    
    private func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        isLoading = false
        cancelRetry()
    }
}

