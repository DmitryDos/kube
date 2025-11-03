import SwiftUI

struct StackSectionView: View {
    let tracks: [Track]
    let currentIndex: Int
    let onSelectIndex: (Int) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                    StackTrackView(
                        track: track,
                        isCurrent: index == currentIndex,
                        onTap: { onSelectIndex(index) }
                    )
                }
            }
        }
    }
}


