import SwiftUI

struct QueueView: View {
    @ObservedObject private var queueService = QueueService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Environment(\.isLandscape) private var isLandscape
    @State private var tracks: [Track] = []
    @State private var draggingItem: Track?
    @State private var dragOffset: CGFloat = 0
    @State private var draggedFromIndex: Int?
    @State private var visualDragIndex: Int?
    @State private var hoverIndex: Int?

    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                Text("Очередь треков")
                    .font(.title2.bold())
                    .foregroundColor(themeObserver.themedAccentColor)
                    .padding()
                    .padding(.top, isLandscape ? 20 : 0)

                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                            if hoverIndex == index && draggingItem != nil {
                                placeholder
                            }

                            if draggingItem?.id != track.id {
                                TrackRow(
                                    track: track,
                                    state: queueService.getTrackState(track),
                                    isDragging: false,
                                    dragOffset: .zero,
                                    isHovered: hoverIndex == index,
                                    onTap: { handleTap(track) },
                                    onDelete: canDeleteTrack(track) ? { deleteTrack(track) } : nil,
                                    onDragChanged: { value in
                                        handleDragChange(value, track: track, index: index)
                                    },
                                    onDragEnded: {
                                        handleDrop()
                                    }
                                )
                            }
                        }

                        if hoverIndex == tracks.count && draggingItem != nil {
                            placeholder
                        }
                    }
                    .animation(.easeInOut(duration: 0.15), value: hoverIndex)
                }
            }

            if let draggingItem, let fromIndex = visualDragIndex {
                TrackRow(
                    track: draggingItem,
                    state: queueService.getTrackState(draggingItem),
                    isDragging: true,
                    dragOffset: .zero,
                    isHovered: false,
                    onTap: {},
                    onDelete: nil,
                    onDragChanged: nil,
                    onDragEnded: nil
                )
                .frame(height: 70)
                .offset(y: CGFloat(fromIndex + 1) * 76 + dragOffset)
                .zIndex(1000)
                .allowsHitTesting(false)
            }
        }
        .onAppear(perform: loadTracks)
        .onChange(of: queueService.currentQueue) { _ in refreshTracks() }
        .onChange(of: queueService.wishlistQueue) { _ in refreshTracks() }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.white.opacity(0.4))
            .frame(height: 70)
            .padding(.horizontal, 4)
    }

    private func handleDragChange(_ value: DragGesture.Value, track: Track, index: Int) {
        let trackState = queueService.getTrackState(track)
        guard trackState == .upcoming || trackState == .played else { return }

        if draggingItem == nil {
            draggingItem = track
            draggedFromIndex = index
            hoverIndex = index
            visualDragIndex = index

            if trackState == .played {
                let newIndex = max(0, queueService.getCurrentQueueCount() - 1)
                queueService.movePlayedToUpcoming(track)
                draggedFromIndex = newIndex
                visualDragIndex = index
                hoverIndex = newIndex
            }
        }

        dragOffset = value.translation.height
        updateHoverIndex()
    }

    private func updateHoverIndex() {
        guard let visualIndex = visualDragIndex else { return }
        
        let rowHeight: CGFloat = 76
        let positionChange = Int((dragOffset / rowHeight + 0.3).rounded())
        
        let minIndex = queueService.currentIndex >= 0 ? queueService.currentIndex + 1 : 0
        var targetIndex = max(minIndex, min(tracks.count - 1, visualIndex + positionChange))
        if (targetIndex > draggedFromIndex ?? 0) {
            targetIndex += 1
        }
        
        withAnimation(.easeInOut(duration: 0.1)) {
            hoverIndex = targetIndex
        }
    }

    private func handleDrop() {
        guard let from = draggedFromIndex, let to = hoverIndex else {
            resetDrag()
            return
        }

        let fromTrackState = queueService.getTrackState(tracks[from])
        guard fromTrackState == .upcoming || fromTrackState == .played else {
            resetDrag()
            return
        }

        let minIndex = queueService.currentIndex >= 0 ? queueService.currentIndex + 1 : 0
        let adjustedTo = max(minIndex, to)
        
        if from != to {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                let track = tracks.remove(at: from)
                
                var finalTo = to
                if to > from { finalTo -= 1 }
                
                let targetIndex = min(finalTo, tracks.count)
                tracks.insert(track, at: targetIndex)
                updateOrder()
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

    private func updateOrder() {
        let upcomingTracks = tracks.filter { queueService.getTrackState($0) == .upcoming }

        var newCurrentQueue: [Track] = []
        var newWishlistQueue: [Track] = []

        if let currentTrack = queueService.getCurrentTrack() {
            newCurrentQueue.append(currentTrack)
        }

        for track in upcomingTracks {
            if queueService.currentQueue.contains(where: { $0.id == track.id }) {
                newCurrentQueue.append(track)
            } else if queueService.wishlistQueue.contains(where: { $0.id == track.id }) {
                newWishlistQueue.append(track)
            }
        }

        queueService.currentQueue = newCurrentQueue
        queueService.wishlistQueue = newWishlistQueue
    }

    private func loadTracks() {
        tracks = queueService.getAllQueueTracks()
    }

    private func refreshTracks() {
        tracks = queueService.getAllQueueTracks()
    }

    private func handleTap(_ track: Track) {
        guard draggingItem == nil else { return }
        let state = queueService.getTrackState(track)
        switch state {
        case .played:
            queueService.movePlayedToUpcoming(track)
            queueService.playTrack(track)
        case .current:
            break
        case .upcoming:
            queueService.moveAfterCurrent(track)
            queueService.playTrack(track)
        case .none:
            break
        }
    }
    
    private func canDeleteTrack(_ track: Track) -> Bool {
        let state = queueService.getTrackState(track)
        return state == .upcoming
    }

    private func deleteTrack(_ track: Track) {
        guard draggingItem == nil else { return }
        queueService.removeTrackFromQueues(track)
        refreshTracks()
    }
}
