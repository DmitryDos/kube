import SwiftUI

struct FloatingActionMenuModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let buttons: [ActionButton]
    @Environment(\.isLandscape) private var isLandscape

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(buttons.prefix(6)) { button in
                    ActionGridButton(
                        title: button.title,
                        icon: button.icon,
                        color: button.color
                    ) {
                        button.action()
                    }
                }

                ForEach(0..<(6 - min(buttons.count, 6)), id: \.self) { _ in
                    Color.clear.frame(height: 70)
                }
            }
            .frame(width: 160)
            .padding(16)
            .overlay(ModalMarkerView().allowsHitTesting(false))
            .background(themeObserver.primaryGlassColor)
            .cornerRadius(16)
        }
        .padding(.top, isLandscape ? 15 : 60)
        .padding(.trailing, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}
