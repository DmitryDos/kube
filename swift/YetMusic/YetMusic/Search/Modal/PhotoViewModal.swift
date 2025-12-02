//
//  PhotoViewModal.swift
//  YetMusic
//
//  Created by Dmitry Dostovalov on 04.11.2025.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct PhotoViewModal: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    let track: Track?
    let initialImage: UIImage?
    let isReadOnly: Bool
    let onSave: ((UIImage) -> Void)?
    
    @StateObject private var subModalProvider = SubModalProvider()
    @State private var image: UIImage?
    @State private var editedImage: UIImage?
    @State private var selectedFilter: PhotoFilter = .none
    @State private var showCrop: Bool = false
    @State private var cropRect: CGRect = .zero
    @State private var showFilters: Bool = false
    
    private var canEdit: Bool {
        // Проверяем авторизацию и владельца
        guard let track = track else {
            return !isReadOnly && onSave != nil
        }
        
        guard AuthService.shared.isAuthenticated else {
            return false
        }
        
        guard let ownerId = track.ownerUserId,
              let currentUserId = AuthService.shared.currentUser?.id else {
            return false
        }
        
        return !isReadOnly && ownerId == currentUserId
    }
    
    private var imageURL: URL? {
        return track?.imageURL
    }
    
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0
    
    private var safeAreaTop: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.top
        }
        return 0
    }
    
    init(track: Track, isReadOnly: Bool = false, onSave: ((UIImage) -> Void)? = nil) {
        self.track = track
        self.initialImage = nil
        self.isReadOnly = isReadOnly
        self.onSave = onSave
    }
    
    init(image: UIImage, isReadOnly: Bool = false, onSave: ((UIImage) -> Void)? = nil) {
        self.track = nil
        self.initialImage = image
        self.isReadOnly = isReadOnly
        self.onSave = onSave
    }
    
    var body: some View {
        ZStack {
            // Фон
            Color.black
                .ignoresSafeArea()
            
            
            // Фото с zoom и pan через UIScrollView
            if let image = editedImage ?? self.image {
                ZoomableImageView(image: image)
                    .overlay(
                        ModalMarkerView()
                            .allowsHitTesting(false)
                    )
                    .onTapGesture {
                        // Закрываем фильтры если они открыты (только если можно редактировать)
                        if canEdit && subModalProvider.modal != nil {
                            subModalProvider.dismiss()
                        }
                    }
                    .onAppear {
                        // Загружаем изображение при появлении
                        if let initialImage = initialImage {
                            self.image = initialImage
                            self.editedImage = initialImage
                        } else if self.image == nil {
                            loadImage()
                        }
                    }
            } else if let url = imageURL {
                ProgressView()
                    .tint(.white)
                    .onAppear {
                        if self.image == nil {
                            loadImageFromURL(url)
                        }
                    }
            } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.5))
                        Text("Ошибка загрузки")
                            .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Крестик справа сверху
            VStack {
                HStack {
                    Spacer()
                    Button {
                        ModalProvider.shared.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 24)
                }
                Spacer()
            }
            .padding(.top, safeAreaTop + 8)
            .overlay(
                ModalMarkerView()
                    .allowsHitTesting(false)
            )
            
            // Панель инструментов снизу (если можно редактировать)
            if canEdit {
                VStack {
                    Spacer()
                    HStack(spacing: 20) {
                        Button {
                            // Открываем фильтры через SubModalProvider (автоматически заменит предыдущую модалку если есть)
                            subModalProvider.show(
                                PhotoFilterModal(
                                    selectedFilter: $selectedFilter,
                                    image: image,
                                    subModalProvider: subModalProvider,
                                    onFilterSelected: { filter in
                                        applyFilter(filter)
                                        subModalProvider.dismiss()
                                    }
                                ),
                                requiresBackground: true
                            )
                        } label: {
                            Image(systemName: "camera.filters")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(25)
                        }
                        
                        Button {
                            showCrop.toggle()
                        } label: {
                            Image(systemName: "crop")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(25)
                        }
                        
                        Spacer()
                        
                        Button {
                            saveImage()
                        } label: {
                            Text("Сохранить")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(themeObserver.themedAccentColor)
                                .cornerRadius(25)
                        }
                    }
                    .padding()
                    .padding(.bottom)
                }
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            ModalMarkerView()
                .allowsHitTesting(false)
        )
        .withSubModalProvider(subModalProvider)
    }
    
    private func loadImage() {
        // Загружаем изображение из кеша AsyncTrackImage или напрямую
        if let url = imageURL {
            loadImageFromURL(url)
        }
    }
    
    private func loadImageFromURL(_ url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let loadedImage = UIImage(data: data) {
                    await MainActor.run {
                        self.image = loadedImage
                        self.editedImage = loadedImage
                    }
                }
            } catch {
                print("Failed to load image: \(error)")
            }
        }
    }
    
    private func applyFilter(_ filter: PhotoFilter) {
        guard let image = image else { return }
        
        Task {
            let filteredImage = await filter.apply(to: image)
            await MainActor.run {
                editedImage = filteredImage
            }
        }
    }
    
    private func saveImage() {
        guard let imageToSave = editedImage ?? image else { return }
        
        // Если есть callback onSave, вызываем его
        if let onSave = onSave {
            onSave(imageToSave)
            ModalProvider.shared.dismiss()
            return
        }
        
        // Сохраняем в галерею
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
        
        // Также обновляем на сервере, если нужно
        Task {
            // TODO: Загрузить отредактированное изображение на сервер
            await MainActor.run {
                ModalProvider.shared.dismiss()
            }
        }
    }
    
    
    // MARK: - Zoomable Image View с UIScrollView
    struct ZoomableImageView: UIViewRepresentable {
        let image: UIImage
        
        func makeUIView(context: Context) -> UIScrollView {
            let scrollView = UIScrollView()
            scrollView.delegate = context.coordinator
            scrollView.minimumZoomScale = 1.0
            scrollView.maximumZoomScale = 5.0
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.backgroundColor = .clear
            
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.isUserInteractionEnabled = true
            
            scrollView.addSubview(imageView)
            context.coordinator.imageView = imageView
            context.coordinator.scrollView = scrollView
            
            // Вызываем updateLayout после того, как view появится
            DispatchQueue.main.async {
                context.coordinator.updateLayout()
            }
            
            return scrollView
        }
        
        func updateUIView(_ uiView: UIScrollView, context: Context) {
            // Обновляем изображение если оно изменилось
            if let imageView = context.coordinator.imageView, imageView.image != image {
                imageView.image = image
                context.coordinator.updateLayout()
            }
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator()
        }
        
        class Coordinator: NSObject, UIScrollViewDelegate {
            var imageView: UIImageView?
            var scrollView: UIScrollView?
            
            func updateLayout() {
                guard let imageView = imageView,
                      let scrollView = scrollView,
                      let image = imageView.image else { return }
                
                let scrollViewSize = scrollView.bounds.size
                guard scrollViewSize.width > 0 && scrollViewSize.height > 0 else {
                    DispatchQueue.main.async {
                        self.updateLayout()
                    }
                    return
                }
                
                let imageSize = image.size
                let imageAspect = imageSize.width / imageSize.height
                let viewAspect = scrollViewSize.width / scrollViewSize.height
                
                // Вычисляем размер для fit
                let fittedSize: CGSize
                if imageAspect > viewAspect {
                    fittedSize = CGSize(width: scrollViewSize.width, height: scrollViewSize.width / imageAspect)
                } else {
                    fittedSize = CGSize(width: scrollViewSize.height * imageAspect, height: scrollViewSize.height)
                }
                
                imageView.frame = CGRect(origin: .zero, size: fittedSize)
                scrollView.contentSize = fittedSize
                scrollView.minimumZoomScale = 1.0
                scrollView.maximumZoomScale = 5.0
                scrollView.zoomScale = 1.0
                
                // Центрируем изображение синхронно после установки размеров
                centerImage()
            }
            
            func viewForZooming(in scrollView: UIScrollView) -> UIView? {
                return imageView
            }
            
            func scrollViewDidZoom(_ scrollView: UIScrollView) {
                centerImage()
            }
            
            func centerImage() {
                guard let imageView = imageView,
                      let scrollView = scrollView else { return }
                
                let scrollViewSize = scrollView.bounds.size
                let imageViewSize = imageView.frame.size
                
                let horizontalPadding = max(0, (scrollViewSize.width - imageViewSize.width) / 2)
                let verticalPadding = max(0, (scrollViewSize.height - imageViewSize.height) / 2)
                
                scrollView.contentInset = UIEdgeInsets(
                    top: verticalPadding,
                    left: horizontalPadding,
                    bottom: verticalPadding,
                    right: horizontalPadding
                )
            }
        }
    }
    
    enum PhotoFilter: String, CaseIterable {
        case none = "Оригинал"
        case sepia = "Сепия"
        case noir = "Черно-белое"
        case vivid = "Яркое"
        case dramatic = "Драматичное"
        case cool = "Холодное"
        case warm = "Теплое"
        
        func apply(to image: UIImage) async -> UIImage? {
            guard let ciImage = CIImage(image: image) else { return image }
            
            let context = CIContext()
            var outputImage: CIImage = ciImage
            
            switch self {
            case .none:
                return image
            case .sepia:
                let filter = CIFilter.sepiaTone()
                filter.inputImage = ciImage
                filter.intensity = 0.8
                outputImage = filter.outputImage ?? ciImage
            case .noir:
                let filter = CIFilter.photoEffectNoir()
                filter.inputImage = ciImage
                outputImage = filter.outputImage ?? ciImage
            case .vivid:
                let filter = CIFilter.colorControls()
                filter.inputImage = ciImage
                filter.saturation = 1.5
                filter.brightness = 0.1
                filter.contrast = 1.2
                outputImage = filter.outputImage ?? ciImage
            case .dramatic:
                // Используем комбинацию фильтров для драматичного эффекта
                let filter = CIFilter.colorControls()
                filter.inputImage = ciImage
                filter.contrast = 1.5
                filter.saturation = 1.3
                filter.brightness = -0.1
                outputImage = filter.outputImage ?? ciImage
            case .cool:
                // Используем TemperatureAndTint для холодного эффекта
                let filter = CIFilter.temperatureAndTint()
                filter.inputImage = ciImage
                filter.neutral = CIVector(x: 6500, y: 0)
                filter.targetNeutral = CIVector(x: 8000, y: 0) // Более холодная температура
                outputImage = filter.outputImage ?? ciImage
            case .warm:
                // Используем TemperatureAndTint для теплого эффекта
                let filter = CIFilter.temperatureAndTint()
                filter.inputImage = ciImage
                filter.neutral = CIVector(x: 6500, y: 0)
                filter.targetNeutral = CIVector(x: 5000, y: 0) // Более теплая температура
                outputImage = filter.outputImage ?? ciImage
            }
            
            guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                return image
            }
            
            return UIImage(cgImage: cgImage)
        }
    }
    
    /// Модалка для выбора фильтров
    struct PhotoFilterModal: View {
        @Binding var selectedFilter: PhotoFilter
        let image: UIImage?
        let subModalProvider: SubModalProvider
        let onFilterSelected: (PhotoFilter) -> Void
        @ObservedObject private var themeObserver = ThemeObserver.shared
        
        private var safeAreaBottom: CGFloat {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                return window.safeAreaInsets.bottom
            }
            return 0
        }
        
        var body: some View {
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    HStack {
                        Text("Фильтры")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        IconButton(
                            systemName: "xmark",
                            action: { subModalProvider.dismiss() },
                            color: .white
                        )
                    }
                    .padding()
                    
                    PhotoFilterPickerView(
                        selectedFilter: $selectedFilter,
                        image: image,
                        onFilterSelected: { filter in
                            onFilterSelected(filter)
                            // Не закрываем модалку при выборе фильтра
                        }
                    )
                    .padding(.bottom, safeAreaBottom) // Отступ на safeArea снизу для контента
                }
                .background(
                    // Один фон до края экрана (игнорирует safeArea)
                    Color.black.opacity(0.8)
                        .ignoresSafeArea(edges: .bottom)
                )
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .frame(maxHeight: 300)
                .overlay(
                    // Обертываем всю модалку в ModalMarkerView чтобы клики внутри не закрывали её
                    ModalMarkerView()
                        .allowsHitTesting(false)
                )
            }
            .ignoresSafeArea(edges: .bottom) // Игнорируем safeArea для всего контейнера
        }
    }
    
    struct PhotoFilterPickerView: View {
        @Binding var selectedFilter: PhotoFilter
        let image: UIImage?
        let onFilterSelected: (PhotoFilter) -> Void
        
        var body: some View {
            VStack(spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(PhotoFilter.allCases, id: \.self) { filter in
                            FilterThumbnailView(
                                filter: filter,
                                image: image,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                                onFilterSelected(filter)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 120)
            }
            .padding(.bottom)
        }
    }
    
    struct FilterThumbnailView: View {
        let filter: PhotoFilter
        let image: UIImage?
        let isSelected: Bool
        let onTap: () -> Void
        
        @State private var filteredThumbnail: UIImage?
        
        var body: some View {
            VStack(spacing: 8) {
                ZStack {
                    if let thumbnail = filteredThumbnail ?? image {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                    }
                    
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 3)
                            .frame(width: 80, height: 80)
                    }
                }
                
                Text(filter.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .onTapGesture {
                onTap()
            }
            .onAppear {
                if let image = image {
                    Task {
                        let filtered = await filter.apply(to: image)
                        await MainActor.run {
                            filteredThumbnail = filtered
                        }
                    }
                }
            }
        }
    }
    
}

// MARK: - Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: [UIRectCorner]) -> some View {
        let cornerSet = corners.isEmpty ? UIRectCorner.allCorners : corners.reduce(UIRectCorner()) { $0.union($1) }
        return clipShape(RoundedCorner(radius: radius, corners: cornerSet))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
