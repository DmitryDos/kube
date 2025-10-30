import SwiftUI

struct VideoLoaderModal: View {
    @ObservedObject var transferService = VideoTransferService.shared

    private var items: [VideoTransferItem] {
        transferService.allTransfers().sorted { $0.title < $1.title }
    }

    @ObservedObject private var themeObserver = ThemeObserver.shared

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            LazyVStack(alignment: .trailing, spacing: 12) {
                ForEach(items) { item in
                    TransferRow(item: item)
                }
                
            }
            .frame(width: .infinity)
            .padding(16)
            .overlay(ModalMarkerView().allowsHitTesting(false))
            .background(themeObserver.secondaryGlassColor)
            .cornerRadius(16)
        }
        .padding(.top, 60)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: 120, alignment: .topTrailing)
    }
}


