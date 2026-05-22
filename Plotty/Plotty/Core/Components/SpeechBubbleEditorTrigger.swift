import SwiftUI

/// 右上に置く「長方形＋しっぽ」風の吹き出しトリガー（作成・編集パネルを開く）。
struct SpeechBubbleEditorTrigger: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .imageScale(.medium)
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                }

                // 下向きのしっぽ（吹き出し感）
                SpeechBubbleTailShape()
                    .fill(.ultraThinMaterial)
                    .frame(width: 18, height: 9)
                    .rotationEffect(.degrees(180))
                    .offset(y: -1)
            }
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

/// 三角形しっぽ（頂点が下向きになるよう親側で回転させる）
private struct SpeechBubbleTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
