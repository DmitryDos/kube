import SwiftUI
import AVFoundation

struct PlaylistTrackView: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @ObservedObject private var queueService = QueueService.shared
    
    let track: Track
    var isEditingMode: Bool = false
    var isSelected: Bool = false
    let onToggle: () -> Void
    let onLongPress: () -> Void
    
    @State private var isPressed = false

    private var isInQueue: Bool {
        return queueService.currentQueue.contains(where: { $0.id == track.id }) ||
               queueService.wishlistQueue.contains(where: { $0.id == track.id })
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncTrackImage(
                track: track,
                cornerRadius: 14
            )

            if isEditingMode {
                VStack {
                    HStack {
                        Button {
                            onToggle()
                        } label: {
                            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                .font(.system(size: 20))
                                .foregroundColor(isSelected ? .orange : .white)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Color.black.opacity(0.7)))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(8)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeObserver.darkColor)
                        .lineLimit(1)
                    
                    Text(track.artist)
                        .font(.system(size: 12))
                        .foregroundColor(themeObserver.darkColor.opacity(0.7))
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(themeObserver.backgroundGlassColor)
                .cornerRadius(8)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
        .appBackground(padding: 6)
        .scaleEffect(isPressed ? 1.05 : 1.0)
        .overlay(
            Group {
                if !isEditingMode && !isInQueue {
                    Button {
                        addTrackToQueue()
                    } label: {
                        Image(systemName: "text.badge.plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(themeObserver.themedPrimaryColor)
                            .frame(width: 32, height: 32)
                            .background(themeObserver.contrastColor)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .offset(x: 4, y: 4)
                }
            },
            alignment: .bottomTrailing
        )
        .onTapGesture {
            if isEditingMode {
                onToggle()
            } else {
                playTrack()
            }
        }
        .onLongPressGesture(minimumDuration: 0.2) {
            onLongPress()
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
    
    private func playTrack() {
        queueService.playTrack(track)
    }
    
    private func addTrackToQueue() {
        queueService.addToWishlist(track)
    }
}
