//
//  TrackRow.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 20.10.2025.
//

import SwiftUICore
import SwiftUI

struct TrackRow: View {
    let track: Track
    let state: TrackState
    let isDragging: Bool
    let dragOffset: CGSize
    let isHovered: Bool
    let onTap: () -> Void
    let onDelete: (() -> Void)?

    let onDragChanged: ((DragGesture.Value) -> Void)?
    let onDragEnded: (() -> Void)?
    
    init(
        track: Track,
        state: TrackState,
        isDragging: Bool = false,
        dragOffset: CGSize = .zero,
        isHovered: Bool = false,
        onTap: @escaping () -> Void,
        onDelete: (() -> Void)? = nil,
        onDragChanged: ((DragGesture.Value) -> Void)? = nil,
        onDragEnded: (() -> Void)? = nil
    ) {
        self.track = track
        self.state = state
        self.isDragging = isDragging
        self.dragOffset = dragOffset
        self.isHovered = isHovered
        self.onTap = onTap
        self.onDelete = onDelete
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
    }

    var body: some View {
        QueueTrackView(
            track: track,
            state: state,
            onTap: onTap,
            onDelete: onDelete,
            isDragging: isDragging,
            onDragChanged: onDragChanged,
            onDragEnded: onDragEnded
        )
        .opacity(isDragging ? 0.95 : 1)
        .scaleEffect(isDragging ? 1.05 : 1)
        .shadow(color: isDragging ? .black.opacity(0.25) : .clear, radius: 8, x: 0, y: 4)
        .background(isHovered ? Color.blue.opacity(0.05) : Color.clear)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}
