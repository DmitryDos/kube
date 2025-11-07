import SwiftUI

struct QueueSideModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared

    var body: some View {
        GeometryReader { geo in
            HStack {
                GlassBlock {
                    VStack(spacing: 0) {
                        QueueView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(.leading, 45)
                    .frame(width: geo.size.width * 0.35, height: .infinity)
                }
                .padding(8)
                
                Spacer()
            }
        }
    }
}


