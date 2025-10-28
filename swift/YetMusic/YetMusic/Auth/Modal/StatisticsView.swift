//
//  StatisticsView.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 25.10.2025.
//

import SwiftUI

struct StatisticsView: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared

    var body: some View {
        ModalContainer(
            title: "Статистика",
        ) {
            VStack(spacing: 16) {
                StatCard(title: "Прослушано треков", value: "156", icon: "music.note")
                StatCard(title: "Время прослушивания", value: "48ч 23м", icon: "clock")
                StatCard(title: "Любимых треков", value: "34", icon: "heart")
                StatCard(title: "Создано плейлистов", value: "12", icon: "music.note.list")
            }
        }
    }
}
