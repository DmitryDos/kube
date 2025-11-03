//
//  GlobalAuthOverlay.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 05.10.2025.
//


//
//  GlobalAuthOverlay.swift
//  YetMusic
//

import SwiftUI
//
//struct GlobalAuthOverlay: View {
//    @ObservedObject private var authService = AuthService.shared
//    @State private var currentPage: Int = 1
//    
//    var body: some View {
//        Color.clear
//            .onReceive(NotificationCenter.default.publisher(for: .currentPageChanged)) { notification in
//                if let page = notification.object as? Int {
//                    currentPage = page
//                    handleAuthChange(page)
//                }
//            }
//    }
//    
//    private func handleAuthChange(_ page: Int) {
//        if !authService.isAuthenticated && page == 3 {
//            DispatchQueue.main.async {
//                NotificationCenter.default.post(name: .currentPageChanged, object: 2)
//            }
//        }
//    }
//}
