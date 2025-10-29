import SwiftUI

struct VideoLoaderButton: View {
    var body: some View {
        Button(action: { ModalProvider.shared.show(VideoLoaderModal()) }) {
            Image(systemName: "tray.full")
                .font(.system(size: 16, weight: .bold))
                .padding(10)
                .background(Color(.systemBackground).opacity(0.8))
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .accessibilityLabel("Стриминг файлов")
    }
}


