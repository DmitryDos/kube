import SwiftUI

struct QueueView: View {
    @ObservedObject private var queueService = QueueService.shared
    @ObservedObject private var historyService = HistoryService.shared
    @ObservedObject private var audioService = AudioPlayerService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Environment(\.isLandscape) private var isLandscape
    @State private var historyItems: [HistoryService.HistoryItem] = []
    @State private var stackTracks: [Track] = []
    @State private var stackIndex: Int = -1
    @State private var upcomingTracks: [Track] = []
    @State private var selectedHeader: HeaderSelection = .recent
    @State private var days: [Date] = []
    @State private var isStackExpanded: Bool = true
    @State private var isQueueExpanded: Bool = true

    private enum HeaderSelection: Equatable {
        case recent
        case day(Date)
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 8) {
                headerChips

                GeometryReader { geo in
                    VStack(alignment: .leading, spacing: 10) {
                        if selectedIsRecent() {
                            let expandedCount = (isStackExpanded ? 1 : 0) + (isQueueExpanded ? 1 : 0)
                            let sectionHeight: CGFloat = expandedCount > 0 ? max(0, (geo.size.height + 50) / CGFloat(expandedCount)) : 0

                            HStack {
                                MiniSectionHeader(title: "Вы слушали:", isExpanded: $isStackExpanded)
                                
                                Spacer()
                            }

                            if isStackExpanded {
                                StackSectionView(
                                    tracks: stackTracks,
                                    currentIndex: stackIndex,
                                    onSelectIndex: { index in
                                        if index == stackIndex {
                                            if audioService.trackInfo.isPlaying { audioService.pause() } else { audioService.play() }
                                        } else {
                                            queueService.playFromStack(index: index)
                                        }
                                        refreshSegments()
                                    }
                                )
                                .frame(maxHeight: sectionHeight - 75)
                            }

                            HStack {
                                MiniSectionHeader(title: "В очереди", isExpanded: $isQueueExpanded)
                                
                                Spacer()
                            }

                            if isQueueExpanded {
                                QueueSectionView(
                                    tracks: upcomingTracks,
                                    onTap: { track in
                                        queueService.playTrack(track)
                                    },
                                    onDelete: { track in
                                        queueService.removeTrackFromQueues(track)
                                        refreshSegments()
                                    },
                                    onReordered: { newOrder in
                                        applyUpcomingOrder(newOrder)
                                    }
                                )
                                .frame(maxHeight: sectionHeight - 75)
                            }
                        } else {
                            HistorySectionView(items: historyItems) { track in
                                queueService.playTrack(track)
                            }
                        }
                    }
                }
            }
        }
        .onAppear(perform: loadTracks)
        .onChange(of: queueService.currentQueue) { _ in refreshSegments() }
        .onChange(of: queueService.wishlistQueue) { _ in refreshSegments() }
        .onChange(of: historyService.lastUpdate) { _ in refreshHeaderDays() }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.white.opacity(0.4))
            .frame(height: 70)
            .padding(.horizontal, 4)
    }

    private var headerChips: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    headerChip(title: "Недавно", isSelected: selectedIsRecent()) {
                        selectedHeader = .recent
                        refreshSegments()
                    }
                    ForEach(days, id: \.self) { day in
                        headerChip(title: historyService.title(for: day), isSelected: selectedIsDay(day)) {
                            selectedHeader = .day(day)
                            refreshSegments()
                        }
                    }
                }
            }
        }
    }

    private func headerChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? themeObserver.themedAccentColor : Color.white.opacity(0.2))
                )
        }
    }

    private func selectedIsRecent() -> Bool {
        if case .recent = selectedHeader { return true }
        return false
    }

    private func selectedIsDay(_ day: Date) -> Bool {
        if case let .day(d) = selectedHeader { return d.startOfDayUTC == day.startOfDayUTC }
        return false
    }

    private func loadTracks() {
        refreshHeaderDays()
        refreshSegments()
    }

    private func refreshSegments() {
        switch selectedHeader {
        case .recent:
            historyItems = []
        case let .day(day):
            historyItems = historyService.items(for: day)
        }

        stackTracks = queueService.currentQueue
        stackIndex = queueService.currentIndex

        upcomingTracks = queueService.wishlistQueue
    }

    private func refreshHeaderDays() {
        days = historyService.availableDays()
    }

    private func applyUpcomingOrder(_ newOrder: [Track]) {
        queueService.wishlistQueue = newOrder
        refreshSegments()
    }
}
