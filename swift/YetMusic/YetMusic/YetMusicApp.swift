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

extension Notification.Name {
    static let currentPageChanged = Notification.Name("currentPageChanged")
}

@main
struct MusicApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var currentPage: Int = 2

    var body: some Scene {
        WindowGroup {
            MainContentView(current: $currentPage)
                .overlay(GlobalPlayerOverlay(currentPage: $currentPage))
                .overlay(GlobalAuthOverlay())
                .environmentObject(AuthService.shared)
                .environmentObject(ThemeObserver.shared)
        }
    }
}

struct MainContentView: View {
    @Binding var current: Int
    
    @StateObject private var orientation = OrientationObserver()
    @EnvironmentObject private var themeObserver: ThemeObserver
    @State private var scrollOffset: CGFloat = 0
    @State private var isMenuExpanded = false
    
    private var pages: [AnyView] {
        [
            AnyView(FullPlayerView().statusBar(hidden: orientation.isLandscape)),
            AnyView(QueueView()),
            AnyView(PlaylistsView()),
            AnyView(AuthView(authService: AuthService.shared))
        ]
    }
    
    private var menuButtons: [ActionButton] {
        [
            ActionButton(
                title: "Тема",
                icon: themeObserver.isDarkTheme ? "sun.max.fill" : "moon.fill",
                color: .orange
            ) {
                withAnimation {
                    themeObserver.toggleTheme()
                }
            },
            
            ActionButton(
                title: "Профиль",
                icon: "person.crop.circle",
                color: .blue
            ) {
                current = 3
            },
            
            ActionButton(
                title: "Добавить треки",
                icon: "arrow.down.circle.fill",
                color: .yellow
            ) {
                ModalProvider.shared.show(AddTrackModal())
            },
        ]
    }
    
    @State private var pageOffsets: [CGFloat] = Array(repeating: 0, count: 4)
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ParallaxBackground(scrollOffset: $scrollOffset, isLandscape: orientation.isLandscape)
                    .ignoresSafeArea()
                
                TabView(selection: $current) {
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
                buttons: menuButtons,
                isExpanded: $isMenuExpanded,
                isLandscape: orientation.isLandscape,
                currentPage: current)
            .ignoresSafeArea(.all, edges: [.top, .bottom])
            .modifier(IgnoreSafeAreaWhenLandscape(isLandscape: orientation.isLandscape && current == 0))
        }
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
