import SwiftUI

struct HistorySectionView: View {
    let items: [HistoryService.HistoryItem]
    let onTap: (Track) -> Void

    var body: some View {
        if !items.isEmpty {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(items, id: \.id) { item in
                        HistoryRow(item: item, onTap: onTap)
                    }
                }
            }
        }
    }
}

private struct HistoryRow: View {
    let item: HistoryService.HistoryItem
    let onTap: (Track) -> Void
    @ObservedObject private var themeObserver = ThemeObserver.shared

    var body: some View {
        HStack(spacing: 12) {
            Color.clear.frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeObserver.textColor)
                    .lineLimit(1)
                Text(item.artist)
                    .font(.system(size: 11))
                    .foregroundColor(themeObserver.primaryGlassColor)
                    .lineLimit(1)
            }
            Spacer()
            Text(formatDuration(item.duration))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeObserver.textColor)
        }
        .padding(.horizontal, 12)
        .frame(height: 70)
        .background(themeObserver.contrastColor)
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            if let track = item.track { onTap(track) }
        }
    }

    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}


