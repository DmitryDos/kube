import SwiftUI
import AVFoundation

struct AddTrackModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @State private var urlString: String = ""
    @State private var trackTitle: String = ""
    @State private var trackArtist: String = ""
    @State private var isImporting: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var importMethod: ImportMethod = .file
    @State private var selectedFileURL: URL?
    @State private var showMetadataFields: Bool = false
    @State private var downloadedURL: URL?
    @State private var selectedThumbnail: UIImage?
    @State private var showImagePicker: Bool = false
    
    enum ImportMethod {
        case url, file
    }

    private var providerButton: AnyView? {
        if showMetadataFields {
            return AnyView(
                WideButton(
                    title: "Сохранить трек",
                    action: saveTrack,
                    isEnabled: !isLoading
                )
                .padding(.horizontal)
            )
        } else if importMethod == .url && !urlString.isEmpty {
            return AnyView(
                WideButton(
                    title: "Загрузить",
                    action: {},
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
            title: "Добавить трек",
            bottomButton: providerButton
        ) {
            VStack(spacing: 20) {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                if showMetadataFields {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Информация о треке")
                            .font(.headline)
                            .foregroundColor(themeObserver.textColor)
                        
                        // Обложка
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
                        
                        TextFieldWithLabel(
                            title: "Название трека",
                            placeholder: "Введите название",
                            text: $trackTitle
                        )
                        
                        TextFieldWithLabel(
                            title: "Исполнитель",
                            placeholder: "Введите исполнителя",
                            text: $trackArtist
                        )
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Источник")
                        .font(.headline)
                        .foregroundColor(themeObserver.primaryGlassColor)
                    
                    Picker("Метод загрузки", selection: $importMethod) {
                        Text("Файл с устройства").tag(ImportMethod.file)
                            .foregroundColor(themeObserver.secondaryGlassColor)
                        Text("По ссылке").tag(ImportMethod.url)
                            .foregroundColor(themeObserver.secondaryGlassColor)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if importMethod == .url {
                        TextFieldWithLabel(
                            title: "URL видео или аудио",
                            placeholder: "https://example.com/video",
                            text: $urlString
                        )
                    } else {
                        if let selectedFileURL = selectedFileURL {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Файл выбран: \(selectedFileURL.lastPathComponent)")
                                    .font(.caption)
                                    .foregroundColor(themeObserver.textColor)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
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
            allowedContentTypes: [.audio, .movie, .video, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedThumbnail)
        }
    }

    private func saveTrack() {
        guard let fileURL = selectedFileURL else {
            errorMessage = "Выберите файл для загрузки"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Загружаем видео
                let video = try await UploadService.shared.uploadVideo(fileURL: fileURL)
                
                // Обновляем метаданные, если они указаны
                if !trackTitle.isEmpty || !trackArtist.isEmpty || selectedThumbnail != nil {
                    try await VideoService.shared.updateVideoMetadata(
                        videoID: video.id,
                        title: trackTitle.isEmpty ? nil : trackTitle,
                        description: trackArtist.isEmpty ? nil : trackArtist,
                        thumbnail: selectedThumbnail
                    )
                }
                
                await MainActor.run {
                    isLoading = false
                    ModalProvider.shared.dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Ошибка загрузки видео: \(error.localizedDescription)"
                    isLoading = false
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
                
                extractMetadata(from: tempURL) { title, artist in
                    DispatchQueue.main.async {
                        self.trackTitle = title ?? url.deletingPathExtension().lastPathComponent
                            .replacingOccurrences(of: "_", with: " ")
                            .replacingOccurrences(of: "-", with: " ")
                        self.trackArtist = artist ?? "Unknown Artist"
                        self.showMetadataFields = true
                    }
                }
                
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
    
    private func extractTitleFromURL(_ url: URL) -> String {
        let lastPath = url.lastPathComponent
        if lastPath.isEmpty || lastPath == "/" {
            return "Downloaded Track"
        }
        return url.deletingPathExtension().lastPathComponent
    }
}
