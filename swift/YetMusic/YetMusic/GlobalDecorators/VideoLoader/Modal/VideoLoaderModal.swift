import SwiftUI

struct VideoLoaderModal: View {
    @ObservedObject var transferService = VideoTransferService.shared

    private var items: [VideoTransferItem] {
        transferService.allTransfers().sorted { $0.title < $1.title }
    }

    @ObservedObject private var themeObserver = ThemeObserver.shared

    @Environment(\.isLandscape) private var isLandscape

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            Text("Загрузки")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeObserver.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            
            LazyVStack(alignment: .trailing, spacing: 12) {
                ForEach(items) { item in
                    TransferRow(item: item)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 180, maxHeight: isLandscape ? 240 : 360, alignment: .top)
        }
        .overlay(ModalMarkerView().allowsHitTesting(false))
        .padding(.top, isLandscape ? 12 : 60)
        .background(themeObserver.darkColor)
        .cornerRadius(16)
        .frame(maxWidth: isLandscape ? 420 : .infinity,
               maxHeight: isLandscape ? 260 : 440,
               alignment: .top)
        .ignoresSafeArea()
    }
}
