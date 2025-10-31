import SwiftUI

struct VideoLoaderModal: View {
    @ObservedObject var transferService = VideoTransferService.shared

    private var items: [VideoTransferItem] {
        transferService.allTransfers().sorted { $0.title < $1.title }
    }

    @ObservedObject private var themeObserver = ThemeObserver.shared

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
            .frame(width: .infinity, height: 360)
        }
        .overlay(ModalMarkerView().allowsHitTesting(false))
        .padding(16)
        .background(themeObserver.darkColor)
        .padding(.top, 60)
        .cornerRadius(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}
