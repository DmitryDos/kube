import SwiftUI

struct ParallaxBackground: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Binding var scrollOffset: CGFloat
    let totalPages: Int = 4
    let isLandscape: Bool

    var body: some View {
        let overlayColor = themeObserver.backgroundColor.opacity(0.6)
        
        GeometryReader { geo in
            if !isLandscape {
                let pageWidth = geo.size.width
                let totalWidth = pageWidth * CGFloat(totalPages)
                let targetCenterX = pageWidth * 2.5
                let imageCenterX = totalWidth / 2
                let centerOffset = targetCenterX - imageCenterX

                ZStack {
                    if let backgroundImage = themeObserver.backgroundImage {
                        backgroundImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: totalWidth, height: geo.size.height)
                            .offset(x: -scrollOffset * 0.5 - centerOffset)
                            .blur(radius: themeObserver.enableBackgroundBlur ? 10 : 0)
                            .ignoresSafeArea()
                    } else {
                        Image("Background")
                            .resizable()
                            .scaledToFill()
                            .frame(width: totalWidth, height: geo.size.height)
                            .offset(x: -scrollOffset * 0.5 - centerOffset)
                            .blur(radius: themeObserver.enableBackgroundBlur ? 10 : 0)
                            .ignoresSafeArea()
                    }
                    
                    Rectangle()
                                            .fill(overlayColor)
                                            .frame(width: totalWidth, height: geo.size.height)
                                            .offset(x: -scrollOffset * 0.5 - centerOffset)
                                            .ignoresSafeArea()

                    ParallaxLayerBack(scrollOffset: $scrollOffset, centerOffset: centerOffset, geo: geo, totalWidth: totalWidth / 2)
                    ParallaxLayerMiddle(scrollOffset: $scrollOffset, centerOffset: centerOffset, geo: geo, totalWidth: totalWidth / 1.2)
                    ParallaxLayerFront(scrollOffset: $scrollOffset, centerOffset: centerOffset, geo: geo, totalWidth: totalWidth * 1.2)
                }
            } else {
                if let backgroundImage = themeObserver.backgroundImage {
                    backgroundImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .blur(radius: themeObserver.enableBackgroundBlur ? 10 : 0)
                        .ignoresSafeArea()
                } else {
                    Image("Background")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .blur(radius: themeObserver.enableBackgroundBlur ? 10 : 0)
                        .ignoresSafeArea()
                }
                
                Rectangle()
                                        .fill(overlayColor)
                                        .frame(width: geo.size.width, height: geo.size.height)
                                        .ignoresSafeArea()
            }
        }
    }
}

struct ParallaxLayerBack: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Binding var scrollOffset: CGFloat
    let centerOffset: CGFloat
    let geo: GeometryProxy
    let totalWidth: CGFloat

    var body: some View {
        ZStack { shapes }
            .offset(x: -scrollOffset * 0.5 + centerOffset)
            .ignoresSafeArea()
    }

    var shapes: some View {
        Group {
            Circle().frame(width: 36, height: 36).position(x: totalWidth*0.1, y: geo.size.height*0.85)
            Triangle().frame(width: 32, height: 32).position(x: totalWidth*0.3, y: geo.size.height*0.8)
                .rotationEffect(.degrees(30))
            Rectangle().frame(width: 42, height: 42).position(x: totalWidth*0.7, y: geo.size.height*0.90)
                .rotationEffect(.degrees(20))
            Star().frame(width: 32, height: 32).position(x: totalWidth*0.7, y: geo.size.height*0.85)
                .rotationEffect(.degrees(60))
            Circle().frame(width: 24, height: 24).position(x: totalWidth*0.9, y: geo.size.height*0.8)
            Triangle().frame(width: 36, height: 36).position(x: totalWidth*0.2, y: geo.size.height*0.9)
                .rotationEffect(.degrees(45))
            Rectangle().frame(width: 30, height: 30).position(x: totalWidth*0.4, y: geo.size.height*0.85)
                .rotationEffect(.degrees(10))
            Star().frame(width: 36, height: 36).position(x: totalWidth*0.6, y: geo.size.height*0.95)
                .rotationEffect(.degrees(30))
        }
        .foregroundColor(themeObserver.backgroundAccentColor.opacity(0.7))
        .blur(radius: 1)
    }
}

// Средний слой
struct ParallaxLayerMiddle: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Binding var scrollOffset: CGFloat
    let centerOffset: CGFloat
    let geo: GeometryProxy
    let totalWidth: CGFloat

    var body: some View {
        ZStack { shapes }
            .offset(x: -scrollOffset * 0.8 + centerOffset)
            .ignoresSafeArea()
    }

    var shapes: some View {
        Group {
            Circle().frame(width: 72, height: 72).position(x: totalWidth*0.15, y: geo.size.height*0.92)
            Triangle().frame(width: 60, height: 60).position(x: totalWidth*0.35, y: geo.size.height*0.85)
                .rotationEffect(.degrees(80))
            Rectangle().frame(width: 66, height: 66).position(x: totalWidth*0.05, y: geo.size.height*0.8)
                .rotationEffect(.degrees(45))
            Star().frame(width: 54, height: 54).position(x: totalWidth*0.75, y: geo.size.height*0.9)
                .rotationEffect(.degrees(20))
            Triangle().frame(width: 66, height: 66).position(x: totalWidth*0.1, y: geo.size.height*0.85)
                .rotationEffect(.degrees(25))
            Rectangle().frame(width: 54, height: 54).position(x: totalWidth*0.65, y: geo.size.height*0.8)
                .rotationEffect(.degrees(70))
            Circle().frame(width: 78, height: 78).position(x: totalWidth*0.25, y: geo.size.height*0.75)
            Star().frame(width: 60, height: 60).position(x: totalWidth*0.85, y: geo.size.height*0.87)
                .rotationEffect(.degrees(50))
        }
        .foregroundColor(themeObserver.backgroundAccentColor.opacity(0.5))
        .blur(radius: 2)
    }
}

// Ближний слой
struct ParallaxLayerFront: View {
    @ObservedObject private var themeObserver = ThemeObserver.shared
    @Binding var scrollOffset: CGFloat
    let centerOffset: CGFloat
    let geo: GeometryProxy
    let totalWidth: CGFloat

    var body: some View {
        ZStack { shapes }
            .offset(x: -scrollOffset * 1.2 + centerOffset)
            .ignoresSafeArea()
    }

    var shapes: some View {
        Group {
            Circle().frame(width: 144, height: 144).position(x: -totalWidth*0.04, y: geo.size.height*0.85)
            Triangle().frame(width: 96, height: 96).position(x: totalWidth*0.45, y: geo.size.height*0.8)
            Rectangle().frame(width: 108, height: 108).position(x: totalWidth*0.55, y: geo.size.height*0.55)
            Star().frame(width: 120, height: 120).position(x: totalWidth*0.8, y: geo.size.height*0.4)
            Circle().frame(width: 130, height: 130).position(x: totalWidth*0.24, y: geo.size.height*0.6)
            Star().frame(width: 110, height: 110).position(x: totalWidth*0.5, y: geo.size.height*0.25)
        }
        .foregroundColor(themeObserver.backgroundAccentColor.opacity(0.3))
        .blur(radius: 3)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let points = 5
        let radius = min(rect.width, rect.height)/2
        let angle = Double.pi*2/Double(points*2)
        for i in 0..<points*2 {
            let r = i % 2 == 0 ? radius : radius/2
            let x = center.x + CGFloat(cos(Double(i)*angle - Double.pi/2)*Double(r))
            let y = center.y + CGFloat(sin(Double(i)*angle - Double.pi/2)*Double(r))
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        p.closeSubpath()
        return p
    }
}
