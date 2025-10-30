import SwiftUI

struct VideoLoaderMenu: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Environment(\.isLandscape) private var isLandscape

    @Binding var isExpanded: Bool
    @ObservedObject private var modalProvider = ModalProvider.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !isExpanded {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        openMenu()
                        isExpanded = true
                    }
                }) {
                    ZStack {
                        Image(systemName: "tray.full")
                            .font(.system(size: 28))
                            .foregroundColor(themeObserver.themedAccentColor)
                            .frame(width: 50, height: 50)
                            .background(themeObserver.contrastColor)
                            .cornerRadius(12)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.top, isLandscape ? 16 : 60)
        .padding(.leading, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func openMenu() {
        modalProvider.show(
            VideoLoaderModal(),
            onClose: {
                withAnimation {
                    isExpanded = false
                }
            }
        )
    }
}


