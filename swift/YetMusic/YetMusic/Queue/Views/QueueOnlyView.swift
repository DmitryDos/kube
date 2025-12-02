import SwiftUI

/// Переиспользуемый компонент для отображения только очереди (без чипсов и истории)
struct QueueOnlyView: View {
    @ObservedObject private var queueService = QueueService.shared
    @ObservedObject private var historyService = HistoryService.shared
    
    var body: some View {
        QueueSectionView(
            tracks: queueService.wishlistQueue,
            onTap: { track in
                queueService.playTrack(track)
                historyService.recordPlayed(track)
            },
            onDelete: { track in
                queueService.removeTrackFromQueues(track)
            },
            onReordered: { newOrder in
                queueService.wishlistQueue = newOrder
            }
        )
    }
}

