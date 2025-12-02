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
    }
}
