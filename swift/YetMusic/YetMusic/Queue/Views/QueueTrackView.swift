import SwiftUICore
import SwiftUI
import AVFoundation
import UIKit

struct QueueTrackView: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let track: Track
    let onTap: () -> Void
    let onDelete: (() -> Void)?
    let isDragging: Bool

    let onDragChanged: ((DragGesture.Value) -> Void)?
    let onDragEnded: (() -> Void)?
    
    @State private var containerWidth: CGFloat = 0

    private var rowHeight: CGFloat = 55

    private var shouldShowImage: Bool {
        containerWidth > 420
    }
    
    init(
        track: Track,
        onTap: @escaping () -> Void,
        onDelete: (() -> Void)? = nil,
        isDragging: Bool = false,
        onDragChanged: ((DragGesture.Value) -> Void)? = nil,
        onDragEnded: (() -> Void)? = nil
    ) {
        self.track = track
        self.onTap = onTap
        self.onDelete = onDelete
        self.isDragging = isDragging
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                    Color.clear
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeObserver.accentColor)
                }
                .frame(width: 24)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 3)
                        .onChanged { value in onDragChanged?(value) }
                        .onEnded { _ in onDragEnded?() }
                )

            if shouldShowImage {
                AsyncTrackImage(
                    track: track,
                    cornerRadius: 0,
                    width: rowHeight * 16 / 9
                )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 13,
                                weight: .medium))
                    .foregroundColor(themeObserver.textColor)
                    .lineLimit(1)
                
                Text(track.desc)
                    .font(.system(size: 11))
                    .foregroundColor(themeObserver.primaryGlassColor)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(formatDuration(track.duration))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeObserver.textColor)
                
                if let onDelete = onDelete {
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
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        containerWidth = geometry.size.width
                    }
                    .onChange(of: geometry.size.width) { newWidth in
                        containerWidth = newWidth
                    }
            }
        )
        .background(backgroundView)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.clear, lineWidth: 0)
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
            themeObserver.contrastColor
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
