import SwiftUI

struct VideoLoaderButton: View {
    @State private var showModal = false

    var body: some View {
        Button(action: { showModal = true }) {
            Image(systemName: "tray.full")
                .font(.system(size: 16, weight: .bold))
                .padding(10)
                .background(Color(.systemBackground).opacity(0.8))
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .sheet(isPresented: $showModal) {
            VideoLoaderModal()
        }
        .accessibilityLabel("Стриминг файлов")
    }
}


