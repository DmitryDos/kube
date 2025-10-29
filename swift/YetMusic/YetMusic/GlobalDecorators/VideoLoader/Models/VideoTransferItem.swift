import Foundation

enum VideoTransferDirection {
    case upload
    case download
}

final class VideoTransferItem: Identifiable, ObservableObject {
    let id = UUID()
    let title: String
    let fileURL: URL?
    let direction: VideoTransferDirection
    let iconName: String

    @Published var sentBytes: Int64 = 0
    @Published var totalBytes: Int64 = 0
    @Published var isFinished: Bool = false
    @Published var isFailed: Bool = false

    init(title: String, fileURL: URL?, direction: VideoTransferDirection, iconName: String = "square.and.arrow.up") {
        self.title = title
        self.fileURL = fileURL
        self.direction = direction
        self.iconName = iconName
    }
}


