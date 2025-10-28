import SwiftUI

struct FloatingActionMenu: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Environment(\.isLandscape) private var isLandscape
    let buttons: [ActionButton]

    @Binding var isExpanded: Bool
    @ObservedObject private var modalProvider = ModalProvider.shared

    var body: some View {
            VStack(alignment: .trailing, spacing: 12) {
                if !isExpanded {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            openMenu()
                            isExpanded = true
                        }
                    }) {
                        ZStack {
                            Image(systemName: "ellipsis")
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
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private func openMenu() {
        modalProvider.show(
            FloatingActionMenuModal(buttons: buttons, isExpanded: $isExpanded),
            onClose: {
                withAnimation {
                    isExpanded = false
                }
            }
        )
    }
}


struct WithFloatingMenuModifier: ViewModifier {
    let buttons: [ActionButton]
    let isLandscape: Bool
    let currentPage: Int
    @Binding var isExpanded: Bool
    
    func body(content: Content) -> some View {
        content.overlay(
            Group {
                if !(isLandscape && currentPage == 0) {
                    FloatingActionMenu(buttons: buttons, isExpanded: $isExpanded)
                        .zIndex(9999)
                }
            }
        )
    }
}
extension View {
    func withFloatingMenu(buttons: [ActionButton], isExpanded: Binding<Bool>, isLandscape: Bool, currentPage: Int) -> some View {
        self.modifier(WithFloatingMenuModifier(buttons: buttons, isLandscape: isLandscape, currentPage: currentPage, isExpanded: isExpanded))
    }
}
