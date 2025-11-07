//
//  TrackInfo.swift
//  YetMusic
//

import Foundation

struct TrackInfo {
    var track: Track?
    var isPlaying: Bool
    var isBuffering: Bool
    var currentTime: TimeInterval
    var duration: TimeInterval
    var progress: Double
    var bufferedProgress: Double
}
