import SwiftUI

struct ModalContainer<Content: View>: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Environment(\.isLandscape) private var isLandscape
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
        GeometryReader { geo in
            if isLandscape {
                // В горизонтальном режиме: основная часть на весь экран с большими отступами
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
                    .frame(height: 60)
                    .padding(.horizontal, 110)
                    .background(themeObserver.contrastColor)
                    
                    ScrollView {
                        content
                            .padding(.vertical, 30)
                            .padding(.horizontal, 110)
                    }
                    .background(themeObserver.contrastColor)
                    
                    if let bottomButton = bottomButton {
                        bottomButton
                            .padding(.vertical, 30)
                            .padding(.horizontal, 110)
                            .background(themeObserver.contrastColor)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .overlay(
                    ModalMarkerView()
                        .allowsHitTesting(false)
                )
            } else {
                // В вертикальном режиме: основная часть ограничена
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
                    .frame(height: 60)
                    .padding(.horizontal, 16)
            .background(themeObserver.contrastColor)
            
            ScrollView {
                content
                            .padding(.vertical, 16)
                    .padding(.horizontal, 8)
            }
            .background(themeObserver.contrastColor)
            
            if let bottomButton = bottomButton {
                bottomButton
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                    .background(themeObserver.contrastColor)
            }
        }
                .frame(
                    width: UIScreen.main.bounds.width * 0.94,
                    height: UIScreen.main.bounds.height * 0.70
                )
                .background(themeObserver.contrastColor)
                .cornerRadius(20)
                .shadow(color: themeObserver.blackColor.opacity(0.3), radius: 20, x: 0, y: 10)
        .overlay(
            ModalMarkerView()
                .allowsHitTesting(false)
        )
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            }
        }
    }
}
