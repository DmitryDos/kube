import SwiftUICore
import SwiftUI
import AVFoundation
import UIKit

struct QueueTrackView: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let track: Track
    let state: TrackState
    let onTap: () -> Void
    let onDelete: (() -> Void)?
    let isDragging: Bool

    let onDragChanged: ((DragGesture.Value) -> Void)?
    let onDragEnded: (() -> Void)?

    private var rowHeight: CGFloat {
        state == .current ? 90 : 70
    }
    
    private var imageSize: CGFloat {
        state == .current ? 70 : 60
    }
    
    init(
        track: Track,
        state: TrackState,
        onTap: @escaping () -> Void,
        onDelete: (() -> Void)? = nil,
        isDragging: Bool = false,
        onDragChanged: ((DragGesture.Value) -> Void)? = nil,
        onDragEnded: (() -> Void)? = nil
    ) {
        self.track = track
        self.state = state
        self.onTap = onTap
        self.onDelete = onDelete
        self.isDragging = isDragging
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
    }

    var body: some View {
        HStack(spacing: 12) {
            if state == .upcoming || state == .played {
                ZStack {
                            Color.clear
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeObserver.accentColor)
                        }
                        .frame(width: 44)
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 3)
                                .onChanged { value in onDragChanged?(value) }
                                .onEnded { _ in onDragEnded?() }
                        )
            } else {
                Color.clear.frame(width: 20)
            }

            AsyncTrackImage(
                track: track,
                cornerRadius: 0,
                width: 120
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: state == .current ? 15 : 13,
                                weight: state == .current ? .semibold : .medium))
                    .foregroundColor(themeObserver.textColor)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.system(size: state == .current ? 13 : 11))
                    .foregroundColor(themeObserver.primaryGlassColor)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(formatDuration(track.duration))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeObserver.secondaryColor)
                
                if state == .upcoming, let onDelete = onDelete {
                    IconButton(
                        systemName: "trash",
                        action: onDelete,
                        color: themeObserver.accentColor
                    )
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(height: rowHeight)
        .background(backgroundView)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(state == .current ? themeObserver.primaryColor : .clear, lineWidth: state == .current ? 2 : 0)
        )
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isDragging {
                onTap()
            }
        }
    }
    
    private var backgroundView: some View {
        Group {
            switch state {
            case .current:
                LinearGradient(
                    colors: [themeObserver.secondaryGlassColor, themeObserver.themedAccentColor.opacity(0.06)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .played:
                themeObserver.secondaryGlassColor
            case .upcoming:
                themeObserver.secondaryGlassColor
            case .none:
                Color.black.opacity(0)
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
