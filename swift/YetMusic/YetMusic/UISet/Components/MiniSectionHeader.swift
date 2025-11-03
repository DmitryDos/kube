import SwiftUI

struct MiniSectionHeader: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let title: String
    @Binding var isExpanded: Bool
    let height: CGFloat
    let width: CGFloat

    init(title: String, isExpanded: Binding<Bool>, height: CGFloat = 50, width: CGFloat = 160) {
        self.title = title
        self._isExpanded = isExpanded
        self.height = height
        self.width = width
    }

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(themeObserver.themedPrimaryColor)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeObserver.themedAccentColor)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
            }
            .padding(.horizontal, 12)
            .frame(width: width, height: height)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeObserver.contrastColor)
            )
        }
        .buttonStyle(.plain)
    }

    private func toggle() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isExpanded.toggle()
        }
    }
}


