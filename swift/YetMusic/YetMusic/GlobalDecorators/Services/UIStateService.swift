import Foundation
import Combine

final class UIStateService: ObservableObject {
    static let shared = UIStateService()
    @Published var isFullPlayerVisible: Bool = false
    private init() {}
}


