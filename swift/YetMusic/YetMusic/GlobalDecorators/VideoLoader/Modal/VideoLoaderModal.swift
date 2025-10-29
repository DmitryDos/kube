import SwiftUI

struct VideoLoaderModal: View {
    @ObservedObject var transferService = VideoTransferService.shared

    private var items: [VideoTransferItem] {
        transferService.allTransfers().sorted { $0.title < $1.title }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    TransferRow(item: item)
                }
            }
            .navigationTitle("Стриминг")
        }
    }
}


