import SwiftUI

struct ModalContainer<Content: View>: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let title: String
    let leftButton: AnyView?
    let content: Content
    let bottomButton: AnyView?

    init(
        title: String,
        leftButton: AnyView? = nil,
        bottomButton: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.leftButton = leftButton
        self.bottomButton = bottomButton
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let leftButton = leftButton {
                    leftButton
                } else {
                    Spacer().frame(width: 30, height: 30)
                }
                
                Spacer()
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(themeObserver.themedAccentColor)
                
                Spacer()
                
                IconButton(
                    systemName: "xmark",
                    action: { ModalProvider.shared.dismiss() },
                    color: themeObserver.themedAccentColor
                )
            }
            .padding()
            .background(themeObserver.contrastColor)
            
            ScrollView {
                content
                    .padding(.vertical)
                    .padding(.horizontal, 8)
            }
            .background(themeObserver.contrastColor)
            
            if let bottomButton = bottomButton {
                bottomButton
                    .padding(.vertical)
                    .background(themeObserver.contrastColor)
            }
            
            
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
        .frame(width: UIScreen.main.bounds.width * 0.85)
        .overlay(
            ModalMarkerView()
                .allowsHitTesting(false)
        )
        .background(themeObserver.contrastColor)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}
