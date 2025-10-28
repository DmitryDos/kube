import AVKit

class PiPController: NSObject, ObservableObject {
    static let shared = PiPController()
    
    @Published var isPiPActive = false
    private var pipController: AVPictureInPictureController?
    private var playerLayer: AVPlayerLayer?
    private var hostView: UIView?
    private var isConfigured = false
    
    private var isClosingManually = false
    
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
        guard let pipController = pipController else { return }
        
        if !pipController.isPictureInPictureActive {
            pipController.startPictureInPicture()
        }
    }
    
    func stopPiP() {
        isClosingManually = true
        pipController?.stopPictureInPicture()
    }
}

extension PiPController: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isPiPActive = true
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        isPiPActive = false
        
        if isClosingManually {
            if !AudioPlayerService.shared.trackInfo.isPlaying {
                AudioPlayerService.shared.play()
            }
        } else {
            NotificationCenter.default.post(name: .pipDidClose, object: nil)
        }
        
        isClosingManually = false
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                  failedToStartPictureInPictureWithError error: Error) {
    }
}

extension Notification.Name {
    static let pipDidClose = Notification.Name("pipDidClose")
}
