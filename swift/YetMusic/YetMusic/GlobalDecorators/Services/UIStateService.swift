import Foundation
import Combine

final class UIStateService: ObservableObject {
    static let shared = UIStateService()
    @Published var isFullPlayerVisible: Bool = false
    @Published var isFloatingMenuOpen: Bool = false
    private init() {}
}


