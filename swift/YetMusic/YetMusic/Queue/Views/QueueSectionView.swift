import SwiftUI

struct QueueSectionView: View {
    let tracks: [Track]
    let onTap: (Track) -> Void
    let onDelete: (Track) -> Void
    let onReordered: ([Track]) -> Void

    @State private var localTracks: [Track] = []
    @State private var draggingItem: Track?
    @State private var dragOffset: CGFloat = 0
    @State private var draggedFromIndex: Int?
    @State private var visualDragIndex: Int?
    @State private var hoverIndex: Int?
    @State private var scrollOffset: CGFloat = 0

    private let rowHeight: CGFloat = 51

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(Array(localTracks.enumerated()), id: \.element.id) { index, track in
                        if hoverIndex == index && draggingItem != nil { placeholder }
                        if draggingItem?.id != track.id {
                            QueueTrackView(
                                track: track,
                                onTap: { onTap(track) },
                                onDelete: { onDelete(track) },
                                isDragging: false,
                                onDragChanged: { value in handleDragChange(value, track: track, index: index) },
                                onDragEnded: { handleDrop() }
                            )
                        }
                    }
                    if hoverIndex == localTracks.count && draggingItem != nil { placeholder }
                }
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: QueueScrollOffsetKey.self, value: proxy.frame(in: .named("queueScroll")).minY)
                    }
                )
            }
            .coordinateSpace(name: "queueScroll")
            .onPreferenceChange(QueueScrollOffsetKey.self) { value in
                scrollOffset = -value
            }

            if let draggingItem, let fromIndex = visualDragIndex {
                QueueTrackView(
                    track: draggingItem,
                    onTap: {},
                    onDelete: {},
                    isDragging: true,
                    onDragChanged: nil,
                    onDragEnded: nil
                )
                .frame(height: rowHeight + 4)
                .offset(y: CGFloat(fromIndex) * (rowHeight + 6) + 6 + dragOffset - scrollOffset)
                .zIndex(1000)
                .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: hoverIndex)
        .onAppear { localTracks = tracks }
        .onChange(of: tracks) { newValue in localTracks = newValue }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.white.opacity(0.4))
            .frame(height: rowHeight + 4)
            .padding(.horizontal, 4)
    }

    private func handleDragChange(_ value: DragGesture.Value, track: Track, index: Int) {
        if draggingItem == nil {
            draggingItem = track
            draggedFromIndex = index
            hoverIndex = index
            visualDragIndex = index
        }
        dragOffset = value.translation.height
        updateHoverIndex()
    }

    private func updateHoverIndex() {
        guard let visualIndex = visualDragIndex else { return }
        let positionChange = Int((dragOffset / rowHeight + 0.3).rounded())
        var targetIndex = max(0, min(localTracks.count - 1, visualIndex + positionChange))
        if (targetIndex > (draggedFromIndex ?? 0)) { targetIndex += 1 }
        withAnimation(.easeInOut(duration: 0.1)) { hoverIndex = targetIndex }
    }

    private func handleDrop() {
        guard let from = draggedFromIndex, let to = hoverIndex else { resetDrag(); return }
        if from != to {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                let track = localTracks.remove(at: from)
                var finalTo = to
                if to > from { finalTo -= 1 }
                let targetIndex = min(finalTo, localTracks.count)
                localTracks.insert(track, at: targetIndex)
                onReordered(localTracks)
            }
        }
        resetDrag()
    }

    private func resetDrag() {
        draggingItem = nil
        draggedFromIndex = nil
        visualDragIndex = nil
        hoverIndex = nil
        dragOffset = 0
    }
}

private struct QueueScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


