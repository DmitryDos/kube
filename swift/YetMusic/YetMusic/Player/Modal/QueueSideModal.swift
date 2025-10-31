import SwiftUI

struct QueueSideModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Color.clear
                
                VStack(spacing: 0) {
                    HStack {
                        Text("Очередь")
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
                    
                    QueueView()
                        .background(themeObserver.contrastColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geo.size.width * 0.35, height: geo.size.height)
                .background(themeObserver.contrastColor)
                .overlay(ModalMarkerView().allowsHitTesting(false))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .ignoresSafeArea()
        }
    }
}


