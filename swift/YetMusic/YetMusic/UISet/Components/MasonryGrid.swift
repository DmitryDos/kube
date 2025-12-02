//
//  MasonryGrid.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI

struct MasonryGrid<Content: View, Item: Identifiable>: View {
    let items: [Item]
    let columns: Int
    let spacing: CGFloat
    let content: (Item) -> Content
    
    var body: some View {
        GeometryReader { geometry in
            let columnWidth = (geometry.size.width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
            
            HStack(alignment: .top, spacing: spacing) {
                ForEach(0..<columns, id: \.self) { columnIndex in
                    VStack(spacing: spacing) {
                        ForEach(itemsForColumn(columnIndex), id: \.id) { item in
                            content(item)
                                .frame(width: columnWidth)
                        }
                    }
                    .frame(width: columnWidth)
                }
            }
        }
        .frame(height: calculateHeight(columnWidth: nil))
    }
    
    private func itemsForColumn(_ columnIndex: Int) -> [Item] {
        items.enumerated().compactMap { index, item in
            index % columns == columnIndex ? item : nil
        }
    }
    
    private func calculateHeight(columnWidth: CGFloat?) -> CGFloat {
        // Временная высота, будет пересчитана при рендеринге
        return CGFloat(items.count / columns + 1) * 300
    }
}
