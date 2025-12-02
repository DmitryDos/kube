//
//  FilterSettingsModal.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI

struct FilterSettingsModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Binding var selectedFilters: Set<String>
    @Binding var sortOrder: SortOrder
    let availableFilters: [String]
    let onApply: () -> Void
    let onReset: () -> Void
    
    @State private var searchText: String = ""
    @State private var tempSelectedFilters: Set<String>
    @State private var tempSortOrder: SortOrder
    
    enum SortOrder: String, CaseIterable {
        case newest = "Новые - старые"
        case oldest = "Старые - новые"
        case popular = "Популярные"
    }
    
    init(
        selectedFilters: Binding<Set<String>>,
        sortOrder: Binding<SortOrder>,
        availableFilters: [String],
        onApply: @escaping () -> Void,
        onReset: @escaping () -> Void
    ) {
        self._selectedFilters = selectedFilters
        self._sortOrder = sortOrder
        self.availableFilters = availableFilters
        self.onApply = onApply
        self.onReset = onReset
        self._tempSelectedFilters = State(initialValue: selectedFilters.wrappedValue)
        self._tempSortOrder = State(initialValue: sortOrder.wrappedValue)
    }
    
    var filteredFilters: [String] {
        if searchText.isEmpty {
            return Array(availableFilters.prefix(10))
        }
        return availableFilters.filter { $0.localizedCaseInsensitiveContains(searchText) }.prefix(10).map { $0 }
    }
    
    var body: some View {
        ModalContainer(
            title: "Фильтры",
            bottomButton: AnyView(
                HStack(spacing: 12) {
                    Button {
                        onReset()
                        tempSelectedFilters.removeAll()
                        tempSortOrder = .newest
                        ModalProvider.shared.dismiss()
                    } label: {
                        Text("Сбросить")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeObserver.themedAccentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(themeObserver.contrastColor)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        selectedFilters = tempSelectedFilters
                        sortOrder = tempSortOrder
                        onApply()
                        ModalProvider.shared.dismiss()
                    } label: {
                        Text("Применить")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(themeObserver.themedAccentColor)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            )
        ) {
            VStack(spacing: 20) {
                // Текстовое поле для поиска фильтров
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeObserver.textColor.opacity(0.6))
                    
                    TextField("Поиск фильтров", text: $searchText)
                        .foregroundColor(themeObserver.textColor)
                }
                .padding()
                .background(themeObserver.contrastColor)
                .cornerRadius(12)
                
                // Список фильтров (до 10, несколько строк)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Фильтры")
                        .font(.headline)
                        .foregroundColor(themeObserver.textColor)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(filteredFilters, id: \.self) { filter in
                            Button {
                                if tempSelectedFilters.contains(filter) {
                                    tempSelectedFilters.remove(filter)
                                } else {
                                    tempSelectedFilters.insert(filter)
                                }
                            } label: {
                                Text(filter)
                                    .font(.system(size: 14))
                                    .foregroundColor(tempSelectedFilters.contains(filter) ? .white : themeObserver.textColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(tempSelectedFilters.contains(filter) ? themeObserver.themedAccentColor : themeObserver.contrastColor)
                                    )
                            }
                        }
                    }
                }
                
                // Правила сортировки
                VStack(alignment: .leading, spacing: 12) {
                    Text("Сортировка")
                        .font(.headline)
                        .foregroundColor(themeObserver.textColor)
                    
                    VStack(spacing: 8) {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Button {
                                tempSortOrder = order
                            } label: {
                                HStack {
                                    Text(order.rawValue)
                                        .font(.system(size: 16))
                                        .foregroundColor(themeObserver.textColor)
                                    
                                    Spacer()
                                    
                                    if tempSortOrder == order {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(themeObserver.themedAccentColor)
                                    }
                                }
                                .padding()
                                .background(themeObserver.contrastColor)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
        }
    }
}

