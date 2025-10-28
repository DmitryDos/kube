import SwiftUI

struct ActionButtonsPanel: View {
    @ObservedObject private var playlistService = PlaylistService.shared
    @ObservedObject private var queueService = QueueService.shared
    @ObservedObject private var themeObserver = ThemeObserver.shared
    
    let onShare: () -> Void
    var currentTrack: Track?
    
    // Исправленный computed property для проверки лайка
    private var isLiked: Bool {
        guard let track = currentTrack else { return false }
        return playlistService.isTrackLiked(track)
    }
    
    private var isLooping: Bool {
        queueService.isLooping
    }
    
    var body: some View {
        if currentTrack != nil {
            HStack(spacing: 8) {
                Button(action: handleLike) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isLiked ? .red : themeObserver.darkColor)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(themeObserver.darkColor)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: handleLoop) {
                    Image(systemName: isLooping ? "repeat.1" : "repeat")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(themeObserver.darkColor)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 2)
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(themeObserver.backgroundGlassColor)
                    .frame(height: 40)
            )
            .fixedSize(horizontal: true, vertical: true)
        }
    }
    
    private func handleLike() {
        guard let track = currentTrack else { return }
        
        if isLiked {
            playlistService.removeTrackFromPlaylist(track: track, playlistID: PlaylistService.likedPlaylistID)
        } else {
            playlistService.addTrackToPlaylist(track: track, playlistID: PlaylistService.likedPlaylistID)
        }
    }
    
    private func handleLoop() {
        queueService.toggleLoop()
    }
}
