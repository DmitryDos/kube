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
            ZStack(alignment: .bottomTrailing) {
                Color.clear
                
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        TextField("Поиск треков", text: $query)
                            .textFieldStyle(.roundedBorder)
                            .focused($isFocused)
                            .onChange(of: query) { _ in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded = !query.trimmingCharacters(in: .whitespaces).isEmpty
                                }
                            }
                        
                        IconButton(
                            systemName: "xmark",
                            action: { ModalProvider.shared.dismiss() },
                            color: themeObserver.themedAccentColor
                        )
                    }
                    
                    if isExpanded {
                        resultsList
                    }
                }
                .padding(12)
                .frame(
                    width: geo.size.width * (isExpanded ? 0.45 : 0.35),
                    height: isExpanded ? geo.size.height * 0.9 : 80
                )
                .background(themeObserver.contrastColor)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
                .overlay(ModalMarkerView().allowsHitTesting(false))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { isFocused = true } }
    }
    
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(trackController.searchTracks(query: query)) { track in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(themeObserver.textColor)
                            Text(track.artist)
                                .font(.caption)
                                .foregroundColor(themeObserver.textColor.opacity(0.8))
                        }
                        Spacer()
                        IconButton(
                            systemName: "play.fill",
                            action: {
                                queueService.playTrack(track)
                                ModalProvider.shared.dismiss()
                            },
                            color: themeObserver.themedAccentColor
                        )
                    }
                    .padding(10)
                    .background(themeObserver.backgroundGlassColor)
                    .cornerRadius(12)
                }
            }
        }
    }
}


