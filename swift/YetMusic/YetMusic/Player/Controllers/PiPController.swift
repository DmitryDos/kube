import AVKit

class PiPController: NSObject, ObservableObject {
    static let shared = PiPController()
    
    @Published var isPiPActive = false
    private var pipController: AVPictureInPictureController?
    private var playerLayer: AVPlayerLayer?
    private var hostView: UIView?
    private var isConfigured = false
    
    func setupPiP() {
        guard !isConfigured else { return }
        
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            print("❌ PiP не поддерживается")
            return
        }
        
        let player = AudioPlayerService.shared.player
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        playerLayer?.videoGravity = .resizeAspect
        
        hostView = UIView()
        hostView?.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        hostView?.backgroundColor = .clear
        hostView?.layer.addSublayer(playerLayer!)
        
        if let window = UIApplication.shared.windows.first {
            hostView?.alpha = 0.001
            window.addSubview(hostView!)
        }
        
        pipController = AVPictureInPictureController(playerLayer: playerLayer!)
        pipController?.delegate = self
        isConfigured = true
        
        print("✅ PiP настроен")
    }
    
    func startPiP() {
        guard let pipController = pipController else {
            print("⚠️ PiP: pipController не настроен")
            return
        }
        
        guard let player = playerLayer?.player, player.currentItem != nil else {
            print("⚠️ PiP: player не имеет currentItem")
            return
        }
        
        if !pipController.isPictureInPictureActive {
            print("▶️ PiP: Запускаем Picture in Picture")
            pipController.startPictureInPicture()
        } else {
            print("ℹ️ PiP: Уже активен")
        }
    }
    
    func stopPiP() {
        pipController?.stopPictureInPicture()
    }
}

extension PiPController: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("✅ PiP: Успешно запущен")
        isPiPActive = true
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        print("⏹️ PiP: Остановлен")
        isPiPActive = false
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                  failedToStartPictureInPictureWithError error: Error) {
        print("❌ PiP: Ошибка запуска - \(error.localizedDescription)")
        if let nsError = error as NSError? {
            print("   Domain: \(nsError.domain), Code: \(nsError.code)")
            print("   UserInfo: \(nsError.userInfo)")
        }
    }
}
