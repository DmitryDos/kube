//
//  YetMusicApp.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 27.09.2025.
//

//
//  YetMusicApp.swift
//  YetMusic
//

import SwiftUI
import Combine

struct CurrentPageKey: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

extension EnvironmentValues {
    var currentPage: Binding<Int> {
        get { self[CurrentPageKey.self] }
        set { self[CurrentPageKey.self] = newValue }
    }
}

@main
struct MusicApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var currentPage: Int = 2

    var body: some Scene {
        WindowGroup {
            MainContentView()
                .overlay(GlobalPlayerOverlay(currentPage: $currentPage))
                .environmentObject(AuthService.shared)
                .environmentObject(ThemeObserver.shared)
                .environment(\.currentPage, $currentPage)
        }
    }
}

struct MainContentView: View {
    @Environment(\.currentPage) private var currentPage
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var orientation = OrientationObserver()
    @EnvironmentObject private var themeObserver: ThemeObserver
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var audioService = AudioPlayerService.shared
    @State private var scrollOffset: CGFloat = 0
    @State private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Загружаем популярные видео один раз при запуске приложения
        SearchService.shared.loadPopularVideos()
    }

    private var pages: [AnyView] {
        var pagesArray: [AnyView] = [
            AnyView(FullPlayerView().statusBar(hidden: orientation.isLandscape)),
            AnyView(QueueView().padding(.horizontal, orientation.isLandscape ? 92 : 16).padding(.top, orientation.isLandscape ? 24 : 6)),
            AnyView(SearchView().padding(.horizontal, orientation.isLandscape ? 92 : 8).padding(.top, orientation.isLandscape ? 22 : 6)),
            AnyView(AuthView(authService: AuthService.shared).padding(.horizontal, orientation.isLandscape ? 92 : 0)),
        ]
        
        if authService.isAuthenticated {
            pagesArray.append(
                AnyView(PlaylistsView().padding(.horizontal, orientation.isLandscape ? 92 : 8).padding(.top, orientation.isLandscape ? 22 : 6))
            )
        }
        
        return pagesArray
    }
    
    @State private var pageOffsets: [CGFloat] = Array(repeating: 0, count: 5)
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ParallaxBackground(scrollOffset: $scrollOffset, isLandscape: orientation.isLandscape)
                    .ignoresSafeArea()
                
                TabView(selection: currentPage) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        pages[i]
                            .tag(i)
                            .overlay(
                                OffsetProxy()
                                    .onPreferenceChange(OffsetKey.self) { value in
                                        pageOffsets[i] = value
                                        scrollOffset = (CGFloat(i) * geo.size.width - value)
                                    }
                            )
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

            }
            .withFloatingMenu()
        }
        .modifier(IgnoreSafeAreaWhenLandscape(isLandscape: orientation.isLandscape))
        .ignoresSafeArea(.all, edges: [.top, .bottom])
        .withModalProvider() // Перемещаем ModalProvider выше, чтобы он учитывал safeArea
        .environment(\.isLandscape, orientation.isLandscape)
        .environment(\.darkTheme, themeObserver.isDarkTheme)
        .onAppear {
            // Подписываемся на willResignActive - это самый ранний момент, когда еще можно запустить PiP
            NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
                .sink { _ in
                    print("📱 UIApplication.willResignActive - запускаем PiP")
                    
                    // Убеждаемся, что PiP настроен
                    PiPController.shared.setupPiP()
                    
                    let audioService = AudioPlayerService.shared
                    if let track = audioService.trackInfo.track {
                        print("🎵 Найден трек: \(track.title), запускаем PiP")
                        // Запускаем синхронно, пока сцена еще активна
                        PiPController.shared.startPiP()
                    } else {
                        print("⚠️ Трек не найден, PiP не запускается")
                    }
                }
                .store(in: &cancellables)
        }
        .onDisappear {
            // Отписываемся при размонтировании
            cancellables.removeAll()
        }
    }
}

private struct IgnoreSafeAreaWhenLandscape: ViewModifier {
    let isLandscape: Bool
    func body(content: Content) -> some View {
        isLandscape ? AnyView(content.ignoresSafeArea()) : AnyView(content)
    }
}

struct UserAvatarView: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @ObservedObject var authService: AuthService
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            if authService.isAuthenticated {
                Circle()
                    .fill(themeObserver.themedAccentColor)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(authService.currentUser?.name.prefix(1).uppercased() ?? "U")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(themeObserver.whiteColor)
                    )
            } else {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.title2)
                    .foregroundColor(themeObserver.themedAccentColor)
            }
        }
    }
}
