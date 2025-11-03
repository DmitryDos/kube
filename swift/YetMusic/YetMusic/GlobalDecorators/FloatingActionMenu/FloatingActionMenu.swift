import SwiftUI

struct FloatingActionMenu: View {
    @Environment(\.currentPage) private var currentPage
    @State private var isExpanded = false

    private var menuButtons: [ActionButton] {
        [
            ActionButton(
                title: "Тема",
                icon: themeObserver.isDarkTheme ? "sun.max.fill" : "moon.fill",
                color: .orange
            ) {
                withAnimation {
                    themeObserver.toggleTheme()
                }
            },

            ActionButton(
                title: "Профиль",
                icon: "person.crop.circle",
                color: .blue
            ) {
                currentPage.wrappedValue = 3
            },
            
            ActionButton(
                title: "Добавить треки",
                icon: "arrow.down.circle.fill",
                color: .yellow
            ) {
                ModalProvider.shared.show(AddTrackModal())
            },
            ActionButton(
                title: "Загрузка",
                icon: "tray.full",
                color: .pink
            ) {
                ModalProvider.shared.show(VideoLoaderModal())
            },
        ]
    }

    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Environment(\.isLandscape) private var isLandscape

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
            FloatingActionMenuModal(buttons: menuButtons),
            onClose: {
                withAnimation {
                    isExpanded = false
                }
            }
        )
    }
}


struct WithFloatingMenuModifier: ViewModifier {
    let isLandscape: Bool
    @Environment(\.currentPage) private var currentPage
    @ObservedObject private var ui = UIStateService.shared
    
    func body(content: Content) -> some View {
        content.overlay(
            Group {
                if !ui.isFullPlayerVisible {
                    FloatingActionMenu()
                        .zIndex(9999)
                }
            }
        )
    }
}

extension View {
    func withFloatingMenu(isLandscape: Bool) -> some View {
        self.modifier(WithFloatingMenuModifier(isLandscape: isLandscape))
    }
}
