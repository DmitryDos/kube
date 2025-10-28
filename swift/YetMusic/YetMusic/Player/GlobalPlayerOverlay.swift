//
//  GlobalPlayerOverlay.swift
//  YetMusic
//

import SwiftUI

import SwiftUI

struct GlobalPlayerOverlay: View {
    @ObservedObject private var audio = AudioPlayerService.shared
    @Binding var currentPage: Int

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .bottom) {
                Color.clear
            }
        }
        .onAppear {
            PiPController.shared.setupPiP()
        }
        .onChange(of: audio.trackInfo.isPlaying) { isPlaying in
            handlePlaybackStateChange(isPlaying: isPlaying)
        }
    }

    private func handlePlaybackStateChange(isPlaying: Bool) {
        if isPlaying && currentPage != 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                PiPController.shared.startPiP()
            }
        }
    }
}
