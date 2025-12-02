//
//  MusicEditModal.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI
import AVFoundation
import CoreAudio

struct MusicEditModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let track: Track
    let audioURL: URL?
    let onSave: ((URL) -> Void)?
    
    @State private var player: AVPlayer?
    @State private var asset: AVAsset?
    @State private var isPlaying: Bool = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var trimStart: Double = 0
    @State private var trimEnd: Double = 0
    @State private var selectedEffect: AudioEffect = .none
    @State private var showEffects: Bool = false
    @State private var isExporting: Bool = false
    @State private var exportProgress: Double = 0
    @State private var volume: Float = 1.0
    @State private var playbackRate: Float = 1.0
    
    init(track: Track, audioURL: URL? = nil, onSave: ((URL) -> Void)? = nil) {
        self.track = track
        if let url = audioURL {
            self.audioURL = url
        } else if let videoURLString = track.videoURL, let url = URL(string: videoURLString) {
            self.audioURL = url
        } else if let playableURL = track.playableURL {
            self.audioURL = playableURL
        } else {
            self.audioURL = nil
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
                    
                    Text("Редактирование музыки")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        exportAudio()
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
                
                // Обложка и плеер
                VStack(spacing: 16) {
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
                    
                    // Кнопки управления
                    HStack(spacing: 20) {
                        Button {
                            seekToTime(max(0, currentTime - 10))
                        } label: {
                            Image(systemName: "gobackward.10")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        
                        Button {
                            if isPlaying {
                                player?.pause()
                            } else {
                                player?.play()
                            }
                            isPlaying.toggle()
                        } label: {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        
                        Button {
                            seekToTime(min(duration, currentTime + 10))
                        } label: {
                            Image(systemName: "goforward.10")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                }
                .frame(height: 300)
                
                // Панель инструментов
                ScrollView {
                    VStack(spacing: 20) {
                        // Обрезка
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Обрезка")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            AudioTrimView(
                                duration: duration,
                                trimStart: $trimStart,
                                trimEnd: $trimEnd,
                                currentTime: $currentTime,
                                onSeek: { time in
                                    seekToTime(time)
                                }
                            )
                        }
                        
                        // Громкость
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Громкость: \(Int(volume * 100))%")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Slider(value: $volume, in: 0...2) {
                                Text("Volume")
                            } minimumValueLabel: {
                                Image(systemName: "speaker.fill")
                                    .foregroundColor(.white)
                            } maximumValueLabel: {
                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundColor(.white)
                            }
                            .onChange(of: volume) { newValue in
                                player?.volume = newValue
                            }
                            .tint(themeObserver.themedAccentColor)
                        }
                        
                        // Скорость воспроизведения
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Скорость: \(String(format: "%.1fx", playbackRate))")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Slider(value: $playbackRate, in: 0.5...2.0) {
                                Text("Playback Rate")
                            } minimumValueLabel: {
                                Text("0.5x")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            } maximumValueLabel: {
                                Text("2.0x")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                            .onChange(of: playbackRate) { newValue in
                                player?.rate = newValue
                            }
                            .tint(themeObserver.themedAccentColor)
                        }
                        
                        // Эффекты
                        HStack(spacing: 12) {
                            Button {
                                showEffects.toggle()
                            } label: {
                                HStack {
                                    Image(systemName: "waveform")
                                    Text("Эффекты")
                                }
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(showEffects ? themeObserver.themedAccentColor : Color.gray.opacity(0.3))
                                .cornerRadius(20)
                            }
                            
                            Spacer()
                        }
                        
                        // Панель эффектов
                        if showEffects {
                            EffectPickerView(
                                selectedEffect: $selectedEffect,
                                onEffectSelected: { effect in
                                    applyEffect(effect)
                                }
                            )
                        }
                    }
                    .padding()
                    .padding(.bottom)
                }
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
            loadAudio()
        }
        .overlay(
            ModalMarkerView()
                .allowsHitTesting(false)
        )
    }
    
    private func loadAudio() {
        guard let url = audioURL else { return }
        
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
                    newPlayer.volume = volume
                    newPlayer.rate = playbackRate
                    
                    // Наблюдаем за временем воспроизведения
                    let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                    newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                        self.currentTime = CMTimeGetSeconds(time)
                    }
                    
                    self.player = newPlayer
                }
            } catch {
                print("Failed to load audio: \(error)")
            }
        }
    }
    
    private func seekToTime(_ time: Double) {
        guard let player = player else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cmTime)
        currentTime = time
    }
    
    private func applyEffect(_ effect: AudioEffect) {
        // Эффекты будут применены при экспорте
        selectedEffect = effect
    }
    
    private func exportAudio() {
        guard let asset = asset else { return }
        
        isExporting = true
        exportProgress = 0
        
        Task {
            do {
                let outputURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("m4a")
                
                // Удаляем файл, если он существует
                try? FileManager.default.removeItem(at: outputURL)
                
                guard let exportSession = AVAssetExportSession(
                    asset: asset,
                    presetName: AVAssetExportPresetAppleM4A
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
                
                // Применяем эффекты через аудио композицию
                if selectedEffect != .none {
                    let composition = AVMutableComposition()
                    
                    // Добавляем аудио трек
                    guard let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first else {
                        await MainActor.run {
                            isExporting = false
                        }
                        return
                    }
                    
                    let compositionAudioTrack = composition.addMutableTrack(
                        withMediaType: .audio,
                        preferredTrackID: kCMPersistentTrackID_Invalid
                    )
                    
                    try? compositionAudioTrack?.insertTimeRange(
                        timeRange,
                        of: audioTrack,
                        at: .zero
                    )
                    
                    // Применяем эффекты через аудио микс
                    let audioMix = AVMutableAudioMix()
                    let audioMixInputParameters = AVMutableAudioMixInputParameters(track: compositionAudioTrack!)
                    
                    // Применяем эффекты
                    selectedEffect.apply(to: audioMixInputParameters, volume: volume)
                    
                    audioMix.inputParameters = [audioMixInputParameters]
                    exportSession.audioMix = audioMix
                }
                
                exportSession.outputURL = outputURL
                exportSession.outputFileType = .m4a
                
                // Наблюдаем за прогрессом
                let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    DispatchQueue.main.async {
                        self.exportProgress = Double(exportSession.progress)
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

struct AudioTrimView: View {
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

enum AudioEffect: String, CaseIterable {
    case none = "Оригинал"
    case reverb = "Реверберация"
    case echo = "Эхо"
    case distortion = "Дисторшн"
    case lowPass = "Низкие частоты"
    case highPass = "Высокие частоты"
    case pitch = "Изменение тона"
    
    func apply(to parameters: AVMutableAudioMixInputParameters, volume: Float) {
        parameters.setVolume(volume, at: .zero)
        
        // Применяем эффекты через аудио едиты
        // Примечание: полная реализация аудио эффектов требует более сложной обработки
        // Здесь базовая реализация для демонстрации
        switch self {
        case .none:
            break
        case .reverb:
            // Реверберация требует использования AVAudioUnitReverb
            break
        case .echo:
            // Эхо требует использования AVAudioUnitDelay
            break
        case .distortion:
            // Дисторшн требует использования AVAudioUnitDistortion
            break
        case .lowPass:
            // Низкочастотный фильтр
            break
        case .highPass:
            // Высокочастотный фильтр
            break
        case .pitch:
            // Изменение тона требует использования AVAudioUnitTimePitch
            break
        }
    }
}

struct EffectPickerView: View {
    @Binding var selectedEffect: AudioEffect
    let onEffectSelected: (AudioEffect) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AudioEffect.allCases, id: \.self) { effect in
                    Button {
                        selectedEffect = effect
                        onEffectSelected(effect)
                    } label: {
                        Text(effect.rawValue)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedEffect == effect ? Color.blue : Color.gray.opacity(0.3))
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

