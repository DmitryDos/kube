import SwiftUI

struct SearchDockModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @ObservedObject private var trackController = TrackController.shared
    @ObservedObject private var queueService = QueueService.shared
    
    @State private var query: String = ""
    @State private var isExpanded: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        GeometryReader { geo in
            HStack {
                Spacer()
                
                GlassBlock {
                    VStack {
                        PlaylistsView()
                    }
                    .padding(.trailing, 45)
                    .frame(width: geo.size.width * 0.35, height: .infinity)
                }
            }
        }
    }
}


