import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct AddTrackModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @State private var urlString: String = ""
    @State private var trackTitle: String = ""
    @State private var trackDescription: String = ""
    @State private var trackArtist: String = ""
    @State private var isImporting: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var importMethod: ImportMethod = .file
    @State private var selectedFileURL: URL?
    @State private var showMetadataFields: Bool = false
    @State private var selectedThumbnail: UIImage?
    @State private var showImagePicker: Bool = false
    @State private var detectedContentType: ContentType?
    @State private var selectedImage: UIImage?
    
    enum ImportMethod {
        case url, file
    }
    
    enum ContentType {
        case video
        case audio
        case image
    }
    
    private var isImage: Bool {
        detectedContentType == .image
    }
    
    private var isVideoOrAudio: Bool {
        detectedContentType == .video || detectedContentType == .audio
    }

    private var providerButton: AnyView? {
        if showMetadataFields {
            return AnyView(
                WideButton(
                    title: "Сохранить",
                    action: saveTrack,
                    isEnabled: !isLoading
                )
                .padding(.horizontal)
            )
        } else if importMethod == .url && !urlString.isEmpty {
            return AnyView(
                WideButton(
                    title: "Загрузить",
                    action: downloadFromURL,
                    isEnabled: !isLoading
                )
                .padding(.horizontal)
            )
        } else if importMethod == .file && selectedFileURL == nil {
            return AnyView(
                WideButton(
                    title: "Выбрать файл с устройства",
                    action: { isImporting = true },
                    isEnabled: !isLoading
                )
                .padding(.horizontal)
            )
        }
        return nil
    }
    
    var body: some View {
        ModalContainer(
            title: "Добавить контент",
            bottomButton: providerButton
        ) {
            VStack(spacing: 20) {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(themeObserver.errorColor)
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(themeObserver.errorColor.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Источник загрузки
                VStack(alignment: .leading, spacing: 12) {
                    Text("Источник")
                        .font(.headline)
                        .foregroundColor(themeObserver.textColor)
                    
                    Picker("Метод загрузки", selection: $importMethod) {
                        Text("Файл с устройства").tag(ImportMethod.file)
                        Text("По ссылке").tag(ImportMethod.url)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if importMethod == .url {
                        TextFieldWithLabel(
                            title: "URL",
                            placeholder: "https://example.com/file.mp4",
                            text: $urlString
                        )
                    } else {
                        if let selectedFileURL = selectedFileURL {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(themeObserver.successColor)
                                Text("Файл выбран: \(selectedFileURL.lastPathComponent)")
                                    .font(.caption)
                                    .foregroundColor(themeObserver.textColor)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding()
                            .background(themeObserver.successColor.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                // Поля метаданных после выбора файла
                if showMetadataFields {
                    VStack(alignment: .leading, spacing: 16) {
                        // Название (вверху)
                        TextFieldWithLabel(
                            title: "Название",
                            placeholder: "Введите название",
                            text: $trackTitle
                        )
                        
                        // Описание (для фото) или Исполнитель (для видео/музыки)
                        if isImage {
                            TextFieldWithLabel(
                                title: "Описание",
                                placeholder: "Введите описание",
                                text: $trackDescription
                            )
                        } else {
                            TextFieldWithLabel(
                                title: "Исполнитель",
                                placeholder: "Введите исполнителя",
                                text: $trackArtist
                            )
                        }
                        
                        // Для фото: показываем само фото на всю ширину
                        if isImage, let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .cornerRadius(12)
                                .padding(.vertical, 8)
                        }
                        
                        // Для видео/музыки: загрузка обложки
                        if isVideoOrAudio {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Обложка")
                                    .font(.headline)
                                    .foregroundColor(themeObserver.textColor)
                                
                                ZStack(alignment: .bottomTrailing) {
                                    if let thumbnail = selectedThumbnail {
                                        Image(uiImage: thumbnail)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 200)
                                            .cornerRadius(12)
                                            .clipped()
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(themeObserver.contrastColor)
                                            .frame(height: 200)
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(themeObserver.themedPrimaryColor.opacity(0.5))
                                            )
                                    }
                                    
                                    Button {
                                        showImagePicker = true
                                    } label: {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                            .frame(width: 36, height: 36)
                                            .background(themeObserver.themedAccentColor)
                                            .cornerRadius(8)
                                    }
                                    .padding(8)
                                }
                            }
                        }
                    }
                }
                
                if isLoading {
                    ProgressView("Загрузка...")
                        .padding()
                }
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.movie, .video, .mpeg4Movie, .quickTimeMovie, .audio, .mp3, .mpeg4Audio, .image, .jpeg, .png, .gif, .tiff, .heic],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedThumbnail)
        }
        .onChange(of: selectedThumbnail) { newImage in
            // После выбора обложки открываем модалку редактирования
            if let image = newImage {
                ModalProvider.shared.show(
                    PhotoViewModal(
                        image: image,
                        isReadOnly: false,
                        onSave: { editedImage in
                            selectedThumbnail = editedImage
                        }
                    ),
                    requiresBackground: false
                )
            }
        }
    }
    
    private func downloadFromURL() {
        guard let url = URL(string: urlString), !urlString.isEmpty else {
            errorMessage = "Введите корректный URL"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let tempDirectory = FileManager.default.temporaryDirectory
                let fileName = url.lastPathComponent.isEmpty ? "downloaded_file" : url.lastPathComponent
                let tempURL = tempDirectory.appendingPathComponent(UUID().uuidString + "_" + fileName)
                
                try data.write(to: tempURL)
                
                await MainActor.run {
                    selectedFileURL = tempURL
                    detectContentType(from: tempURL)
                    processSelectedFile(tempURL)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func detectContentType(from url: URL) {
        let ext = url.pathExtension.lowercased()
        
        // Видео форматы
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "webm", "flv", "wmv", "3gp"]
        if videoExtensions.contains(ext) {
            detectedContentType = .video
            return
        }
        
        // Аудио форматы
        let audioExtensions = ["mp3", "m4a", "aac", "flac", "wav", "ogg", "wma", "opus"]
        if audioExtensions.contains(ext) {
            detectedContentType = .audio
            return
        }
        
        // Изображения
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
        if imageExtensions.contains(ext) {
            detectedContentType = .image
            return
        }
        
        // Если не определили, пытаемся по MIME типу
        if let uti = UTType(filenameExtension: ext) {
            if uti.conforms(to: .movie) || uti.conforms(to: .video) {
                detectedContentType = .video
            } else if uti.conforms(to: .audio) {
                detectedContentType = .audio
            } else if uti.conforms(to: .image) {
                detectedContentType = .image
            }
        }
        
        // По умолчанию считаем видео
        if detectedContentType == nil {
            detectedContentType = .video
        }
    }
    
    private func processSelectedFile(_ url: URL) {
        if detectedContentType == .image {
            // Для изображений загружаем само изображение
            if let imageData = try? Data(contentsOf: url),
               let image = UIImage(data: imageData) {
                selectedImage = image
            }
        }
        
        // Извлекаем метаданные
        extractMetadata(from: url) { title, artist in
            DispatchQueue.main.async {
                self.trackTitle = title ?? url.deletingPathExtension().lastPathComponent
                    .replacingOccurrences(of: "_", with: " ")
                    .replacingOccurrences(of: "-", with: " ")
                
                if self.isImage {
                    self.trackDescription = ""
                } else {
                    self.trackArtist = artist ?? "Unknown Artist"
                }
                
                self.showMetadataFields = true
                self.isLoading = false
            }
        }
    }

    private func saveTrack() {
        guard let fileURL = selectedFileURL, let contentType = detectedContentType else {
            errorMessage = "Выберите файл для загрузки"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                switch contentType {
                case .video:
                    let video = try await UploadService.shared.uploadVideo(fileURL: fileURL)
                    
                    if !trackTitle.isEmpty || !trackArtist.isEmpty || selectedThumbnail != nil {
                        try await VideoService.shared.updateVideoMetadata(
                            videoID: video.id,
                            title: trackTitle.isEmpty ? nil : trackTitle,
                            description: trackArtist.isEmpty ? nil : trackArtist,
                            thumbnail: selectedThumbnail
                        )
                    }
                    
                    // Открываем модалку редактирования видео
                    await MainActor.run {
                        isLoading = false
                        ModalProvider.shared.dismiss()
                        
                        // Создаем Track из загруженного видео
                        let uploadedTrack = Track(
                            id: video.id,
                            title: trackTitle.isEmpty ? video.title : trackTitle,
                            desc: trackArtist.isEmpty ? video.desc : trackArtist,
                            duration: 0,
                            videoURL: video.videoURL,
                            thumbnailURL: video.thumbnailURL,
                            ownerUserId: video.ownerUserId,
                            dateAdded: video.dateAdded
                        )
                        uploadedTrack.contentType = "video"
                        
                        ModalProvider.shared.show(
                            VideoEditModal(
                                track: uploadedTrack,
                                videoURL: fileURL,
                                onSave: { editedURL in
                                    // Загружаем отредактированное видео
                                    Task {
                                        do {
                                            let editedVideo = try await UploadService.shared.uploadVideo(fileURL: editedURL)
                                            print("Edited video uploaded: \(editedVideo.id)")
                                        } catch {
                                            print("Failed to upload edited video: \(error)")
                                        }
                                    }
                                }
                            ),
                            requiresBackground: false
                        )
                    }
                    return
                    
                case .audio:
                    let music = try await UploadService.shared.uploadAudio(fileURL: fileURL)
                    
                    if !trackTitle.isEmpty || !trackArtist.isEmpty || selectedThumbnail != nil {
                        try await UploadService.shared.updateMusicMetadata(
                            musicID: music.id,
                            title: trackTitle.isEmpty ? nil : trackTitle,
                            artist: trackArtist.isEmpty ? nil : trackArtist,
                            cover: selectedThumbnail
                        )
                    }
                    
                    // Открываем модалку редактирования музыки
                    await MainActor.run {
                        isLoading = false
                        ModalProvider.shared.dismiss()
                        
                        // Создаем Track из загруженной музыки
                        let uploadedTrack = Track(
                            id: music.id,
                            title: trackTitle.isEmpty ? music.title : trackTitle,
                            desc: trackArtist.isEmpty ? music.desc : trackArtist,
                            duration: 0,
                            videoURL: music.videoURL,
                            thumbnailURL: music.thumbnailURL,
                            ownerUserId: music.ownerUserId,
                            dateAdded: music.dateAdded
                        )
                        uploadedTrack.contentType = "audio"
                        
                        ModalProvider.shared.show(
                            MusicEditModal(
                                track: uploadedTrack,
                                audioURL: fileURL,
                                onSave: { editedURL in
                                    // Загружаем отредактированную музыку
                                    Task {
                                        do {
                                            let editedMusic = try await UploadService.shared.uploadAudio(fileURL: editedURL)
                                            print("Edited music uploaded: \(editedMusic.id)")
                                        } catch {
                                            print("Failed to upload edited music: \(error)")
                                        }
                                    }
                                }
                            ),
                            requiresBackground: false
                        )
                    }
                    return
                    
                case .image:
                    let uploadedTrack = try await UploadService.shared.uploadPhoto(fileURL: fileURL)
                    
                    if !trackTitle.isEmpty || !trackDescription.isEmpty {
                        try await UploadService.shared.updatePhotoMetadata(
                            photoID: uploadedTrack.id,
                            title: trackTitle.isEmpty ? nil : trackTitle,
                            description: trackDescription.isEmpty ? nil : trackDescription
                        )
                    }
                    
                    // Очищаем кеш поиска фото, чтобы обновить результаты
                    await MainActor.run {
                        SearchService.shared.clearResults()
                        // Открываем модалку редактирования фото
                        isLoading = false
                        ModalProvider.shared.dismiss()
                        ModalProvider.shared.show(
                            PhotoViewModal(track: uploadedTrack, isReadOnly: false),
                            requiresBackground: false
                        )
                    }
                    return
                }
                
                await MainActor.run {
                    isLoading = false
                    ModalProvider.shared.dismiss()
                }
            } catch {
                await MainActor.run {
                    // Проверяем, является ли ошибка ошибкой авторизации
                    var isUnauthorized = false
                    
                    if let videoError = error as? VideoError {
                        if case .unauthorized = videoError {
                            isUnauthorized = true
                        } else if case .serverError(let statusCode) = videoError, statusCode == 401 {
                            isUnauthorized = true
                        }
                    }
                    
                    if isUnauthorized {
                        // Открываем модалку авторизации вместо показа ошибки
                        ModalProvider.shared.show(AuthModal())
                        isLoading = false
                    } else {
                        let contentTypeName = contentType == .video ? "видео" : contentType == .audio ? "аудио" : "изображения"
                        errorMessage = "Ошибка загрузки \(contentTypeName): \(error.localizedDescription)"
                        isLoading = false
                    }
                }
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Нет доступа к файлу"
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                let tempURL = try copyToTemporaryDirectory(url)
                selectedFileURL = tempURL
                detectContentType(from: tempURL)
                processSelectedFile(tempURL)
                
            } catch {
                errorMessage = "Ошибка обработки файла: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            errorMessage = "Ошибка выбора файла: \(error.localizedDescription)"
        }
    }
    
    private func copyToTemporaryDirectory(_ url: URL) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempURL = tempDirectory.appendingPathComponent(UUID().uuidString + "." + url.pathExtension)
        
        if FileManager.default.fileExists(atPath: tempURL.path) {
            try FileManager.default.removeItem(at: tempURL)
        }
        
        try FileManager.default.copyItem(at: url, to: tempURL)
        return tempURL
    }
    
    private func extractMetadata(from url: URL, completion: @escaping (String?, String?) -> Void) {
        // Для изображений не извлекаем метаданные через AVAsset
        if detectedContentType == .image {
            completion(nil, nil)
            return
        }
        
        Task {
            let asset = AVAsset(url: url)
            
            do {
                let metadata = try await asset.load(.metadata)
                var title: String?
                var artist: String?
                
                for item in metadata {
                    guard let commonKey = item.commonKey else { continue }
                    
                    switch commonKey {
                    case .commonKeyTitle:
                        title = item.stringValue
                    case .commonKeyArtist:
                        artist = item.stringValue
                    default:
                        break
                    }
                }
                
                completion(title, artist)
            } catch {
                completion(nil, nil)
            }
        }
    }
}
