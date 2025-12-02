//
//  SubModalProvider.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI

class SubModalProvider: ObservableObject {
    @Published var modal: ModalItem?
    var onDismiss: (() -> Void)?
    
    func show<Content: View>(_ modal: Content, onClose: (() -> Void)? = nil, requiresBackground: Bool = true) {
        // Закрываем предыдущую модалку если есть
        self.modal?.onClose?()
        
        // Подменяем модалку (всегда только одна)
        let item = ModalItem(
            view: AnyView(modal),
            onClose: {
                onClose?()
                self.onDismiss?()
            },
            requiresBackground: requiresBackground,
            isModalContainer: false,
            disableDismissOnTap: false
        )
        self.modal = item
    }
    
    func dismiss() {
        modal?.onClose?()
        modal = nil
        onDismiss?()
    }
}

// UIView для обработки всех тачей в SubModalProvider
class SubModalBackgroundUIView: UIView {
    var onTouch: () -> Void = {}
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        // Не закрываем модалку автоматически при клике вне модалки
        // Закрытие должно обрабатываться явно (например, через onTapGesture на видео)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Проверяем, попадает ли тач в область модалки
        let instances = ModalMarkerUIView.instances.allObjects
        var touchInsideModal = false
        
        for modal in instances {
            // Проверяем, что modal видим и находится в иерархии
            if modal.superview != nil && !modal.isHidden {
                let modalPoint = modal.convert(point, from: self)
                if modal.bounds.contains(modalPoint) {
                    touchInsideModal = true
                    break
                }
            }
        }
        
        // Если тач внутри модалки - пропускаем дальше (nil = пропустить к дочерним view)
        if touchInsideModal {
            return nil
        }
        
        // Если тач вне модалки - не блокируем, пропускаем дальше (nil = пропустить к дочерним view, например к видео)
        // Закрытие модалки будет обрабатываться в touchesBegan
        return nil
    }
}

struct SubModalGestureDetector: UIViewRepresentable {
    var onTouch: () -> Void
    
    func makeUIView(context: Context) -> SubModalBackgroundUIView {
        let view = SubModalBackgroundUIView()
        view.onTouch = onTouch
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: SubModalBackgroundUIView, context: Context) {
        uiView.onTouch = onTouch
    }
}

struct SubModalProviderView: View {
    @ObservedObject private var subModalProvider: SubModalProvider
    @ObservedObject private var themeObserver = ThemeObserver.shared
    
    init(subModalProvider: SubModalProvider) {
        self.subModalProvider = subModalProvider
    }
    
    var body: some View {
        ZStack {
            if let item = subModalProvider.modal {
                item.view
                
                // Обрабатываем все тачи (не только клики) - размещаем поверх модалки
                SubModalGestureDetector(onTouch: {
                    subModalProvider.dismiss()
                })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .allowsHitTesting(true)
            }
        }
    }
}

extension View {
    func withSubModalProvider(_ subModalProvider: SubModalProvider) -> some View {
        ZStack {
            self
            SubModalProviderView(subModalProvider: subModalProvider)
        }
    }
}

