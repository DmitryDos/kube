//
//  AVPlayerViewControllerRepresented.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.10.2025.
//

import SwiftUI
import AVKit

struct AVPlayerViewControllerRepresented: UIViewControllerRepresentable {
    let player: AVPlayer
    @Binding var isPlaying: Bool
    var showsPlaybackControls: Bool = true
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = showsPlaybackControls
        controller.videoGravity = .resizeAspectFill
        
        if !showsPlaybackControls {
            controller.allowsPictureInPicturePlayback = false
        }

        controller.entersFullScreenWhenPlaybackBegins = true
        controller.exitsFullScreenWhenPlaybackEnds = false
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.showsPlaybackControls = showsPlaybackControls
        
        if isPlaying {
            uiViewController.player?.play()
        } else {
            uiViewController.player?.pause()
        }
    }
}
