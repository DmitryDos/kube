import SwiftUI

struct TransferRow: View {
    @ObservedObject var item: VideoTransferItem

    private var progress: Float {
        guard item.totalBytes > 0 else { return 0 }
        return Float(Double(item.sentBytes) / Double(item.totalBytes))
    }

    private var subtitle: String {
        let sent = ByteCountFormatter.string(fromByteCount: item.sentBytes, countStyle: .file)
        let total = item.totalBytes > 0 ? ByteCountFormatter.string(fromByteCount: item.totalBytes, countStyle: .file) : "—"
        return item.isFinished ? "Готово" : item.isFailed ? "Ошибка" : "\(sent) / \(total)"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.direction == .upload ? "square.and.arrow.up" : "square.and.arrow.down")
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                UIKitProgressView(progress: progress)
                    .frame(height: 2)
            }
        }
        .padding(.vertical, 8)
    }
}


