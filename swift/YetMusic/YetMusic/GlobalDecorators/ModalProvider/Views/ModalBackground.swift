//
//  ModalBackground.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 26.10.2025.
//

import SwiftUI

class ModalBackgroundUIView: UIView {
    var onBackgroundTap: () -> Void = {}
    var isActive: Bool = true
    var blocksClicks: Bool = false

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Если модалка блокирует клики, не пропускаем их дальше
        if blocksClicks {
            // Только для активной модалки проверяем клики вне модалок
            if isActive {
                let instances = ModalMarkerUIView.instances.allObjects
                var clickInsideAnyModal = false

                // Проверяем, попадает ли клик в область ЛЮБОЙ модалки
                for modal in instances {
                    let modalPoint = modal.convert(point, from: self)
                    
                    if modal.bounds.contains(modalPoint) {
                        clickInsideAnyModal = true
                        break
                    }
                }
                
                // Если клик вне всех модалок - закрываем эту модалку
                if !clickInsideAnyModal {
                    onBackgroundTap()
                    return self
                } else {
                    // Если клик внутри модалки - пропускаем его дальше к элементам внутри
                    return nil
                }
            }
            
            // Блокируем клик - не пропускаем дальше
            return self
        }
        
        // Для модалок, которые не блокируют клики - пропускаем их дальше
        // Это позволяет кликам проходить к другим элементам (например, меню)
        
        // Только для активной модалки проверяем клики вне модалок
        if isActive {
        let instances = ModalMarkerUIView.instances.allObjects
            var clickInsideAnyModal = false

            // Проверяем, попадает ли клик в область ЛЮБОЙ модалки
        for modal in instances {
            let modalPoint = modal.convert(point, from: self)
            
            if modal.bounds.contains(modalPoint) {
                    clickInsideAnyModal = true
                    break
            }
        }
        
            // Если клик вне всех модалок - закрываем эту модалку
            if !clickInsideAnyModal {
                onBackgroundTap()
            }
        }
        
        // Всегда возвращаем nil, чтобы клик прошел дальше
        return nil
    }
}

struct ModalBackground<Content: View>: View {
    let onBackgroundTap: () -> Void
    let content: Content
    @State private var marker: ModalMarkerUIView?
    let isActive: Bool
    let blocksClicks: Bool

    init(onBackgroundTap: @escaping () -> Void, isActive: Bool = true, blocksClicks: Bool = false, @ViewBuilder content: () -> Content) {
        self.onBackgroundTap = onBackgroundTap
        self.isActive = isActive
        self.blocksClicks = blocksClicks
        self.content = content()
    }

    var body: some View {
        ZStack {
            GestureDetector(onBackgroundTap: onBackgroundTap, isActive: isActive, blocksClicks: blocksClicks)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            content
        }
    }
}
