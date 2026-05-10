import SwiftUI

// MARK: - Ambient Background
/// 背景は静的レイヤーに固定（Mesh + 大径 blur の毎フレーム更新はスクロール時に著しく重い）。
struct AmbientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            base
                .ignoresSafeArea()
            
            meshLayer
                .ignoresSafeArea()
                .blur(radius: 40)
                .opacity(colorScheme == .dark ? 0.55 : 0.35)
            
            orbA
            orbB
            orbC
            
            grain
                .ignoresSafeArea()
                .opacity(colorScheme == .dark ? 0.05 : 0.04)
                .blendMode(.overlay)
        }
        /// 子ビューが変わらない前提で1枚にまとめ、手前の ScrollView との合成負荷を下げる
        .drawingGroup(opaque: false)
    }
    
    // MARK: - Base
    private var base: some View {
        Color(hex: colorScheme == .dark ? "#0F0E0D" : "#E8E4DC")
    }
    
    // MARK: - Mesh layer (depth gradient, static points)
    private var meshLayer: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: meshPointsStatic,
            colors: meshColors
        )
    }
    
    private var meshPointsStatic: [SIMD2<Float>] {
        [
            SIMD2(0.0, 0.0),
            SIMD2(0.5, 0.0),
            SIMD2(1.0, 0.0),
            SIMD2(0.0, 0.5),
            SIMD2(0.5, 0.55),
            SIMD2(1.0, 0.45),
            SIMD2(0.0, 1.0),
            SIMD2(0.5, 1.0),
            SIMD2(1.0, 1.0)
        ]
    }
    
    private var meshColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(hex: "#0F0E0D"), Color(hex: "#1B1612"), Color(hex: "#0F0E0D"),
                Color(hex: "#231A14"), Color(hex: "#322217"), Color(hex: "#1A1410"),
                Color(hex: "#0F0E0D"), Color(hex: "#161310"), Color(hex: "#0F0E0D")
            ]
        } else {
            return [
                Color(hex: "#E8E4DC"), Color(hex: "#EBE7DF"), Color(hex: "#E8E4DC"),
                Color(hex: "#E5E0D7"), Color(hex: "#E2DDD3"), Color(hex: "#E6E1D8"),
                Color(hex: "#E8E4DC"), Color(hex: "#EAE6DE"), Color(hex: "#E8E4DC")
            ]
        }
    }
    
    // MARK: - Orbs (static; animated offsets were forcing full-screen blur redraws every frame)
    private var orbA: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: colorScheme == .dark
                        ? [Color(hex: "#FFD9A8").opacity(0.16), .clear]
                        : [Color(hex: "#FFCC88").opacity(0.18), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 260
                )
            )
            .frame(width: 460, height: 460)
            .offset(x: 140, y: -180)
            .blur(radius: 50)
    }
    
    private var orbB: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: colorScheme == .dark
                        ? [Color(hex: "#A8C8FF").opacity(0.10), .clear]
                        : [Color(hex: "#88B0FF").opacity(0.10), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 220
                )
            )
            .frame(width: 380, height: 380)
            .offset(x: -130, y: 240)
            .blur(radius: 50)
    }
    
    private var orbC: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: colorScheme == .dark
                        ? [Color(hex: "#FFB0E0").opacity(0.06), .clear]
                        : [Color(hex: "#FF99CC").opacity(0.07), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 200
                )
            )
            .frame(width: 320, height: 320)
            .offset(x: 80, y: 440)
            .blur(radius: 60)
    }
    
    // MARK: - Grain
    private var grain: some View {
        Rectangle()
            .fill(
                AngularGradient(
                    colors: [
                        Color.white.opacity(0.6),
                        Color.black.opacity(0.6),
                        Color.white.opacity(0.6),
                        Color.black.opacity(0.6),
                        Color.white.opacity(0.6)
                    ],
                    center: .center
                )
            )
            .blur(radius: 0.5)
            .opacity(0.5)
    }
}

// MARK: - Background Modifier
struct AmbientBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            AmbientBackground()
            content
        }
    }
}

extension View {
    func ambientBackground(animated: Bool = false) -> some View {
        modifier(AmbientBackgroundModifier())
    }
}

#Preview("Dark") {
    VStack {
        Text("Plotty")
            .font(.system(size: 48, weight: .bold))
            .foregroundStyle(.white)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AmbientBackground())
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    VStack {
        Text("Plotty")
            .font(.system(size: 48, weight: .bold))
            .foregroundStyle(.black)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AmbientBackground())
    .preferredColorScheme(.light)
}
