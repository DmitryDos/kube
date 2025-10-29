import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        // Store completion to call when BackgroundUploadService reports finish
        BackgroundUploadService.shared.backgroundCompletionHandler = completionHandler
    }
}


