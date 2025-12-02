//
//  VideoEditModal.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI
import AVFoundation
import AVKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct VideoEditModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let track: Track
    let videoURL: URL?
    let onSave: ((URL) -> Void)?
    
    @State private var player: AVPlayer?
    @State private var asset: AVAsset?
    @State private var isPlaying: Bool = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var trimStart: Double = 0
    @State private var trimEnd: Double = 0
    @State private var selectedFilter: VideoFilter = .none
    @State private var showFilters: Bool = false
    @State private var isExporting: Bool = false
    @State private var exportProgress: Double = 0
    
    init(track: Track, videoURL: URL? = nil, onSave: ((URL) -> Void)? = nil) {
        self.track = track
        if let url = videoURL {
            self.videoURL = url
        } else if let videoURLString = track.videoURL, let url = URL(string: videoURLString) {
            self.videoURL = url
        } else if let playableURL = track.playableURL {
            self.videoURL = playableURL
        } else {
            self.videoURL = nil
        }
        self.onSave = onSave
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Заголовок с кнопками
                HStack {
                    IconButton(
                        systemName: "xmark",
                        action: { ModalProvider.shared.dismiss() },
                        color: .white
                    )
                    
                    Spacer()
                    
                    Text("Редактирование видео")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        exportVideo()
                    } label: {
                        Text("Сохранить")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(themeObserver.themedAccentColor)
                            .cornerRadius(20)
                    }
                    .disabled(isExporting)
                }
                .padding()
                .padding(.top)
                
                // Видео плеер и обложка
                HStack(spacing: 16) {
                    // Видео плеер
                    if let player = player {
                        VideoPlayerView(
                            player: player,
                            isPlaying: $isPlaying,
                            currentTime: $currentTime,
                            duration: $duration
                        )
                        .frame(height: 300)
                    } else {
                        ProgressView()
                            .tint(.white)
                            .frame(height: 300)
                    }
                    
                    // Обложка (если есть)
                    if let imageURL = track.imageURL {
                        AsyncTrackImage(
                            imageURL: imageURL,
                            cornerRadius: 12,
                            imageContentMode: .fill,
                            showBackground: false,
                            canOpenModal: true,
                            track: track
                        )
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                
                // Панель инструментов
                VStack(spacing: 16) {
                    // Обрезка
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Обрезка")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        VideoTrimView(
                            duration: duration,
                            trimStart: $trimStart,
                            trimEnd: $trimEnd,
                            currentTime: $currentTime,
                            onSeek: { time in
                                seekToTime(time)
                            }
                        )
                    }
                    
                    // Фильтры
                    HStack(spacing: 12) {
                        Button {
                            showFilters.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "camera.filters")
                                Text("Фильтры")
                            }
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(showFilters ? themeObserver.themedAccentColor : Color.gray.opacity(0.3))
                            .cornerRadius(20)
                        }
                        
                        Spacer()
                    }
                    
                    // Панель фильтров
                    if showFilters {
                        FilterPickerView(
                            selectedFilter: $selectedFilter,
                            onFilterSelected: { filter in
                                applyFilter(filter)
                            }
                        )
                    }
                }
                .padding()
                .padding(.bottom)
                .background(Color.black.opacity(0.8))
                
                if isExporting {
                    VStack(spacing: 8) {
                        ProgressView(value: exportProgress)
                            .tint(themeObserver.themedAccentColor)
                        Text("Экспорт: \(Int(exportProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadVideo()
        }
        .overlay(
            ModalMarkerView()
                .allowsHitTesting(false)
        )
    }
    
    private func loadVideo() {
        guard let url = videoURL else { return }
        
        Task {
            let loadedAsset = AVAsset(url: url)
            self.asset = loadedAsset
            
            do {
                let duration = try await loadedAsset.load(.duration)
                let durationSeconds = CMTimeGetSeconds(duration)
                
                await MainActor.run {
                    self.duration = durationSeconds
                    self.trimEnd = durationSeconds
                    
                    let playerItem = AVPlayerItem(asset: loadedAsset)
                    let newPlayer = AVPlayer(playerItem: playerItem)
                    
                    // Наблюдаем за временем воспроизведения
                    let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                    newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                        self.currentTime = CMTimeGetSeconds(time)
                    }
                    
                    self.player = newPlayer
                }
            } catch {
                await MainActor.run {
                    print("Failed to load video: \(error)")
                }
            }
        }
    }
    
    private func seekToTime(_ time: Double) {
        guard let player = player else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cmTime)
        currentTime = time
    }
    
    private func applyFilter(_ filter: VideoFilter) {
        // Фильтры будут применены при экспорте
        selectedFilter = filter
    }
    
    private func exportVideo() {
        guard let asset = asset else { return }
        
        isExporting = true
        exportProgress = 0
        
        Task {
            do {
                let outputURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("mp4")
                
                // Удаляем файл, если он существует
                try? FileManager.default.removeItem(at: outputURL)
                
                guard let exportSession = AVAssetExportSession(
                    asset: asset,
                    presetName: AVAssetExportPresetHighestQuality
                ) else {
                    await MainActor.run {
                        isExporting = false
                    }
                    return
                }
                
                // Применяем обрезку
                let startTime = CMTime(seconds: trimStart, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                let endTime = CMTime(seconds: trimEnd, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                let timeRange = CMTimeRange(start: startTime, end: endTime)
                exportSession.timeRange = timeRange
                
                // Применяем фильтр, если выбран
                if selectedFilter != .none {
                    let composition = AVMutableComposition()
                    let videoTrack = composition.addMutableTrack(
                        withMediaType: .video,
                        preferredTrackID: kCMPersistentTrackID_Invalid
                    )
                    
                    guard let assetVideoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
                        await MainActor.run {
                            isExporting = false
                        }
                        return
                    }
                    
                    try? videoTrack?.insertTimeRange(
                        timeRange,
                        of: assetVideoTrack,
                        at: .zero
                    )
                    
                    let videoComposition = AVMutableVideoComposition()
                    videoComposition.renderSize = try await assetVideoTrack.load(.naturalSize)
                    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
                    
                    let instruction = AVMutableVideoCompositionInstruction()
                    instruction.timeRange = CMTimeRange(start: .zero, duration: timeRange.duration)
                    
                    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
                    layerInstruction.setTransform(try await assetVideoTrack.load(.preferredTransform), at: .zero)
                    instruction.layerInstructions = [layerInstruction]
                    
                    // Сохраняем trackID для композитора
                    if let trackID = videoTrack?.trackID {
                        // TrackID уже установлен в videoTrack
                    }
                    
                    videoComposition.instructions = [instruction]
                    
                    // Применяем фильтр через Core Image
                    let filter = selectedFilter.ciFilter
                    if let filter = filter {
                        videoComposition.customVideoCompositorClass = VideoFilterCompositor.self
                        // Сохраняем фильтр для использования в композиторе
                        VideoFilterCompositor.currentFilter = filter
                    }
                    
                    exportSession.videoComposition = videoComposition
                    exportSession.outputURL = outputURL
                    exportSession.outputFileType = .mp4
                } else {
                    exportSession.outputURL = outputURL
                    exportSession.outputFileType = .mp4
                }
                
                // Наблюдаем за прогрессом
                let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak exportSession] _ in
                    DispatchQueue.main.async {
                        if let session = exportSession {
                            self.exportProgress = Double(session.progress)
                        }
                    }
                }
                
                await exportSession.export()
                timer.invalidate()
                
                await MainActor.run {
                    isExporting = false
                    exportProgress = 1.0
                    
                    if exportSession.status == .completed {
                        onSave?(outputURL)
                        ModalProvider.shared.dismiss()
                    } else if let error = exportSession.error {
                        print("Export failed: \(error)")
                    }
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    print("Export error: \(error)")
                }
            }
        }
    }
}

struct VideoPlayerView: View {
    let player: AVPlayer
    @Binding var isPlaying: Bool
    @Binding var currentTime: Double
    @Binding var duration: Double
    
    var body: some View {
        ZStack {
            AVPlayerViewControllerRepresented(
                player: player,
                isPlaying: $isPlaying,
                showsPlaybackControls: true
            )
            
            // Кнопки управления
            HStack {
                Button {
                    if isPlaying {
                        player.pause()
                    } else {
                        player.play()
                    }
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
            }
        }
    }
}

struct VideoTrimView: View {
    let duration: Double
    @Binding var trimStart: Double
    @Binding var trimEnd: Double
    @Binding var currentTime: Double
    let onSeek: (Double) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Слайдер для обрезки
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Фон
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    // Выделенная область
                    let startPercent = trimStart / duration
                    let endPercent = trimEnd / duration
                    let width = geometry.size.width
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: width * (endPercent - startPercent))
                        .offset(x: width * startPercent)
                        .frame(height: 4)
                    
                    // Маркеры начала и конца
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .offset(x: width * startPercent - 8)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newStart = max(0, min(trimEnd - 1, (value.location.x / width) * duration))
                                    trimStart = newStart
                                }
                        )
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .offset(x: width * endPercent - 8)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newEnd = max(trimStart + 1, min(duration, (value.location.x / width) * duration))
                                    trimEnd = newEnd
                                }
                        )
                    
                    // Текущая позиция
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 12, height: 12)
                        .offset(x: (currentTime / duration) * width - 6)
                }
            }
            .frame(height: 40)
            
            // Время
            HStack {
                Text(formatTime(trimStart))
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(formatTime(currentTime))
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Spacer()
                
                Text(formatTime(trimEnd))
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

enum VideoFilter: String, CaseIterable {
    case none = "Оригинал"
    case sepia = "Сепия"
    case noir = "Черно-белое"
    case vivid = "Яркое"
    case dramatic = "Драматичное"
    case cool = "Холодное"
    case warm = "Теплое"
    
    var ciFilter: CIFilter? {
        switch self {
        case .none:
            return nil
        case .sepia:
            let filter = CIFilter.sepiaTone()
            filter.intensity = 0.8
            return filter
        case .noir:
            return CIFilter.photoEffectNoir()
        case .vivid:
            let filter = CIFilter.colorControls()
            filter.saturation = 1.5
            filter.brightness = 0.1
            filter.contrast = 1.2
            return filter
        case .dramatic:
            // Используем комбинацию фильтров для драматичного эффекта
            let filter = CIFilter.colorControls()
            filter.contrast = 1.5
            filter.saturation = 1.3
            filter.brightness = -0.1
            return filter
        case .cool:
            // Используем TemperatureAndTint для холодного эффекта
            guard let filter = CIFilter(name: "CITemperatureAndTint") else {
                // Fallback на colorControls если фильтр недоступен
                let fallbackFilter = CIFilter.colorControls()
                fallbackFilter.saturation = 0.8
                fallbackFilter.brightness = 0.1
                return fallbackFilter
            }
            filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            filter.setValue(CIVector(x: 8000, y: 0), forKey: "inputTargetNeutral")
            return filter
        case .warm:
            // Используем TemperatureAndTint для теплого эффекта
            guard let filter = CIFilter(name: "CITemperatureAndTint") else {
                // Fallback на colorControls если фильтр недоступен
                let fallbackFilter = CIFilter.colorControls()
                fallbackFilter.saturation = 1.2
                fallbackFilter.brightness = 0.1
                return fallbackFilter
            }
            filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            filter.setValue(CIVector(x: 5000, y: 0), forKey: "inputTargetNeutral")
            return filter
        }
    }
}

struct FilterPickerView: View {
    @Binding var selectedFilter: VideoFilter
    let onFilterSelected: (VideoFilter) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(VideoFilter.allCases, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                        onFilterSelected(filter)
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? Color.blue : Color.gray.opacity(0.3))
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// Композитор для применения фильтров к видео
class VideoFilterCompositor: NSObject, AVVideoCompositing {
    static var currentFilter: CIFilter?
    
    var sourcePixelBufferAttributes: [String : Any]? {
        return [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
    }
    
    var requiredPixelBufferAttributesForRenderContext: [String : Any] {
        return [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
    }
    
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {}
    
    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        let instruction = asyncVideoCompositionRequest.videoCompositionInstruction
        
        // Получаем trackID из layerInstructions
        guard let mutableInstruction = instruction as? AVMutableVideoCompositionInstruction,
              let layerInstruction = mutableInstruction.layerInstructions.first as? AVMutableVideoCompositionLayerInstruction else {
            asyncVideoCompositionRequest.finish(with: NSError(domain: "VideoFilterCompositor", code: -1))
            return
        }
        
        // Получаем trackID из layerInstruction
        let trackID = layerInstruction.trackID
        
        guard let sourcePixelBuffer = asyncVideoCompositionRequest.sourceFrame(byTrackID: trackID) else {
            asyncVideoCompositionRequest.finish(with: NSError(domain: "VideoFilterCompositor", code: -1))
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: sourcePixelBuffer)
        var outputImage = ciImage
        
        if let filter = VideoFilterCompositor.currentFilter {
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            if let filteredImage = filter.outputImage {
                outputImage = filteredImage
            }
        }
        
        let context = CIContext()
        guard let outputPixelBuffer = asyncVideoCompositionRequest.renderContext.newPixelBuffer(),
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            asyncVideoCompositionRequest.finish(with: NSError(domain: "VideoFilterCompositor", code: -1))
            return
        }
        
        CVPixelBufferLockBaseAddress(outputPixelBuffer, [])
        let baseAddress = CVPixelBufferGetBaseAddress(outputPixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(outputPixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context2 = CGContext(
            data: baseAddress,
            width: Int(outputImage.extent.width),
            height: Int(outputImage.extent.height),
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        context2?.draw(cgImage, in: outputImage.extent)
        CVPixelBufferUnlockBaseAddress(outputPixelBuffer, [])
        
        asyncVideoCompositionRequest.finish(withComposedVideoFrame: outputPixelBuffer)
    }
    
    func cancelAllPendingVideoCompositionRequests() {}
}

