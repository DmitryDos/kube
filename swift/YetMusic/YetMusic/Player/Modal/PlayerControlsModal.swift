import SwiftUI

struct PlayerControlsModal: View {
    @ObservedObject private var audio = AudioPlayerService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @State private var showingShareSheet = false
    
    let queueService = QueueService.shared

    var body: some View {
        ZStack {
            VStack {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        GlassBlock {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(audio.trackInfo.track?.title ?? "No Track")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(themeObserver.textColor)
                                    .lineLimit(1)
                                
                                Text(audio.trackInfo.track?.artist ?? "Unknown Artist")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeObserver.textColor.opacity(0.8))
                                    .lineLimit(1)
                            }
                            .frame(width: 160, height: 30)
                        }
                        
                        GlassBlock {
                            Button(action: {
                                // TODO: Логика сохранения
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18))
                                    .foregroundColor(themeObserver.textColor)
                                    .frame(width: 30, height: 30)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 6) {
                        GlassBlock {
                            Button(action: {
                                // TODO: Логика лайка
                            }) {
                                Image(systemName: "heart")
                                    .font(.system(size: 18))
                                    .foregroundColor(themeObserver.textColor)
                                    .frame(width: 30, height: 30)
                            }
                        }
                        
                        GlassBlock {
                            Button(action: {
                                showingShareSheet = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18))
                                    .foregroundColor(themeObserver.textColor)
                                    .frame(width: 30, height: 30)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    GlassBlock {
                        Button(action: {
                            // TODO: Логика "Смотрите также"
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "eye")
                                    .font(.system(size: 18))
                                    .foregroundColor(themeObserver.textColor)
                                
                                Text("Смотрите также")
                                    .font(.system(size: 11))
                                    .foregroundColor(themeObserver.textColor)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(width: 150, height: 45)
                        }
                    }
                    
                    Spacer()
                    
                    GlassBlock {
                        VStack(spacing: 0) {
                            VStack(spacing: 6) {
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(themeObserver.textColor.opacity(0.25))
                                        .frame(height: 4)
                                    
                                    Capsule()
                                        .fill(themeObserver.textColor.opacity(0.55))
                                        .frame(width: max(0, CGFloat(audio.trackInfo.bufferedProgress)) * 250, height: 4)
                                        .animation(.linear(duration: 0.1), value: audio.trackInfo.bufferedProgress)
                                    
                                    Slider(
                                        value: Binding(
                                            get: { audio.trackInfo.progress },
                                            set: {
                                                audio.seek(to: $0)
                                            }
                                        ),
                                        in: 0...1,
                                        onEditingChanged: { editing in
                                            if editing {
                                                audio.startSeeking()
                                            } else {
                                                audio.seek(to: audio.trackInfo.progress)
                                                audio.endSeeking()
                                            }
                                        }
                                    )
                                    .tint(themeObserver.textColor)
                                }
                                
                                HStack {
                                    Text(format(audio.trackInfo.currentTime))
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(themeObserver.textColor)
                                    
                                    Spacer()
                                    
                                    Text(format(audio.trackInfo.duration))
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(themeObserver.textColor)
                                }
                            }

                            HStack(spacing: 25) {
                                Button { audio.playPrevious() } label: {
                                    Image(systemName: "backward.end.fill")
                                        .font(.system(size: 30))
                                }
                                
                                Button { audio.seekBackward(seconds: 10) } label: {
                                    Image(systemName: "gobackward.10")
                                        .font(.system(size: 22))
                                }
                                
                                Button {
                                    audio.trackInfo.isPlaying ? audio.pause() : audio.play()
                                } label: {
                                    Image(systemName: audio.trackInfo.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 56))
                                }
                                
                                Button { audio.seekForward(seconds: 10) } label: {
                                    Image(systemName: "goforward.10")
                                        .font(.system(size: 22))
                                }
                                
                                Button { audio.playNext() } label: {
                                    Image(systemName: "forward.end.fill")
                                        .font(.system(size: 30))
                                }
                            }
                            .foregroundColor(themeObserver.textColor)
                        }
                        .frame(width: 300, height: 100)
                    }
                    
                    Spacer()
                    
                    GlassBlock {
                        Button(action: {
                            // TODO: Логика очереди
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 18))
                                    .foregroundColor(themeObserver.textColor)
                                
                                Text("В очереди")
                                    .font(.system(size: 11))
                                    .foregroundColor(themeObserver.textColor)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(width: 150, height: 45)
                        }
                    }
                }
                .padding(.top, 12)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 65)
    }

    private func format(_ t: TimeInterval) -> String {
        guard t.isFinite && !t.isNaN else {
            return "0:00"
        }

        let safeTime = max(0, t)
        let totalSeconds = Int(safeTime)
        
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct GlassBlock<Content: View>: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .appBackground()
            .overlay(ModalMarkerView().allowsHitTesting(false))
    }
}
