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
    @StateObject private var orientation = OrientationObserver()
    @EnvironmentObject private var themeObserver: ThemeObserver
    @State private var scrollOffset: CGFloat = 0

    private var pages: [AnyView] {
        [
            AnyView(FullPlayerView().statusBar(hidden: orientation.isLandscape)),
            AnyView(QueueView().padding(.horizontal, orientation.isLandscape ? 92 : 16).padding(.top, orientation.isLandscape ? 24 : 0)),
            AnyView(PlaylistsView().padding(.horizontal, orientation.isLandscape ? 92 : 8).padding(.top, orientation.isLandscape ? 22 : 8)),
            AnyView(AuthView(authService: AuthService.shared).padding(.horizontal, orientation.isLandscape ? 92 : 0))
        ]
    }

    @State private var pageOffsets: [CGFloat] = Array(repeating: 0, count: 4)
    
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
            .withModalProvider()
            .withFloatingMenu(
                isLandscape: orientation.isLandscape
            )
        }
        .modifier(IgnoreSafeAreaWhenLandscape(isLandscape: orientation.isLandscape))
        .ignoresSafeArea(.all, edges: [.top, .bottom])
        .environment(\.isLandscape, orientation.isLandscape)
        .environment(\.darkTheme, themeObserver.isDarkTheme)
    }
}

private struct IgnoreSafeAreaWhenLandscape: ViewModifier {
    let isLandscape: Bool
    func body(content: Content) -> some View {
        isLandscape ? AnyView(content.ignoresSafeArea()) : AnyView(content)
    }
}

struct UserAvatarView: View {
    @ObservedObject var authService: AuthService
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            if authService.isAuthenticated {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(authService.currentUser?.name.prefix(1).uppercased() ?? "U")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            } else {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
    }
}
