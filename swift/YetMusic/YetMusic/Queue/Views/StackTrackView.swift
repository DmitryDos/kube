import SwiftUI

struct StackTrackView: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let track: Track
    let isCurrent: Bool
    let onTap: () -> Void

    @State private var containerWidth: CGFloat = 0

    init(
        track: Track,
        isCurrent: Bool,
        onTap: @escaping () -> Void,
    ) {
        self.track = track
        self.isCurrent = isCurrent
        self.onTap = onTap
    }

    private var rowHeight: CGFloat { 55 }
    private var shouldShowImage: Bool { containerWidth > 420 }

    var body: some View {
        HStack(spacing: 12) {
            Color.clear.frame(width: 24)

            if shouldShowImage {
                AsyncTrackImage(track: track, cornerRadius: 0, width: rowHeight * 16 / 9)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: isCurrent ? 15 : 13, weight: isCurrent ? .semibold : .medium))
                    .foregroundColor(themeObserver.textColor)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.system(size: isCurrent ? 13 : 11))
                    .foregroundColor(themeObserver.primaryGlassColor)
                    .lineLimit(1)
            }

            Spacer()

            Text(formatDuration(track.duration))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeObserver.textColor)
        }
        .padding(.horizontal, 12)
        .frame(height: rowHeight)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear { containerWidth = geometry.size.width }
                    .onChange(of: geometry.size.width) { newWidth in containerWidth = newWidth }
            }
        )
        .background(
            Group {
                if isCurrent {
                    LinearGradient(
                        colors: [themeObserver.secondaryGlassColor, themeObserver.themedAccentColor.opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    themeObserver.contrastColor
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrent ? themeObserver.primaryColor : .clear, lineWidth: isCurrent ? 2 : 0)
        )
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}


