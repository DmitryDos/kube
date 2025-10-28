//
//  OrientationObserver.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.10.2025.
//


import SwiftUI
import Combine

final class OrientationObserver: ObservableObject {
    @Published var isLandscape: Bool = false
    private var cancellable: AnyCancellable?

    init() {
        cancellable = NotificationCenter.default
            .publisher(for: UIWindowScene.didActivateNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification))
            .sink { [weak self] _ in self?.update() }
        update()
    }

    private func update() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let o = scene.interfaceOrientation
            isLandscape = (o == .landscapeLeft || o == .landscapeRight)
        }
    }
}

private struct IsLandscapeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isLandscape: Bool {
        get { self[IsLandscapeKey.self] }
        set { self[IsLandscapeKey.self] = newValue }
    }
}

extension View {
    func isLandscape(_ value: Bool) -> some View {
        environment(\.isLandscape, value)
    }
}
