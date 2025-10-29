import Foundation
import Combine

final class VideoTransferService: ObservableObject {
    static let shared = VideoTransferService()

    @Published private(set) var transfers: [Int: VideoTransferItem] = [:] // key: taskIdentifier

    func registerUpload(task: URLSessionTask, fileURL: URL, title: String) {
        let item = VideoTransferItem(title: title, fileURL: fileURL, direction: .upload)
        transfers[task.taskIdentifier] = item
        objectWillChange.send()
    }

    func updateProgress(task: URLSessionTask, sent: Int64, expected: Int64) {
        guard let item = transfers[task.taskIdentifier] else { return }
        DispatchQueue.main.async {
            item.sentBytes = sent
            item.totalBytes = expected
        }
    }

    func finish(task: URLSessionTask, error: Error?) {
        guard let item = transfers[task.taskIdentifier] else { return }
        DispatchQueue.main.async {
            item.isFinished = error == nil
            item.isFailed = error != nil
        }
    }

    func allTransfers() -> [VideoTransferItem] {
        Array(transfers.values)
    }
}


