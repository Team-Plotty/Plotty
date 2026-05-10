import SwiftUI

// MARK: - Send Button State
enum SendButtonState {
    case empty       // Idle, no input
    case ready       // Has input, can send
    case processing  // AI thinking
    case done        // Sent successfully
}

// MARK: - Send Button
struct SendButton: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var state: SendButtonState
    var action: () -> Void
    
    private let size: CGFloat = 36
    
    var body: some View {
        Button(action: {
            if state == .ready {
                action()
            }
        }) {
            ZStack {
                backgroundView
                
                if state == .ready {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.35 : 0.6),
                                    Color.white.opacity(colorScheme == .dark ? 0.0 : 0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.6
                        )
                        .frame(width: size - 1, height: size - 1)
                }
                
                if state == .processing {
                    CircleBorderChaser(speed: .fast, lineWidth: 1.8)
                        .frame(width: size, height: size)
                }
                
                iconView
                    .transition(.scale.combined(with: .opacity))
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(state == .empty || state == .processing || state == .done)
        .scaleEffect(state == .ready ? 1.0 : (state == .empty ? 0.94 : 1.0))
        .shadow(
            color: state == .ready
                ? Color.white.opacity(colorScheme == .dark ? 0.18 : 0.0)
                : .clear,
            radius: 8,
            x: 0,
            y: 0
        )
        .animation(.standard, value: state)
        .onChange(of: state) { _, newState in
            if newState == .done {
                DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDuration.doneReset) {
                    withAnimation(.standard) {
                        state = .empty
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch state {
        case .empty:
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [Color.white.opacity(0.08), Color.white.opacity(0.02)]
                                    : [Color.black.opacity(0.05), Color.black.opacity(0.01)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [Color.white.opacity(0.18), Color.white.opacity(0.04)]
                                    : [Color.white.opacity(0.6), Color.black.opacity(0.06)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.6
                        )
                )
            
        case .ready:
            Circle()
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color(hex: "#FFFCF8"), Color(hex: "#E8E4DD")]
                            : [Color(hex: "#1F1A14"), Color(hex: "#0F0E0D")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
        case .processing:
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .fill(
                            colorScheme == .dark
                                ? Color.white.opacity(0.10)
                                : Color.black.opacity(0.06)
                        )
                )
            
        case .done:
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [Color.white.opacity(0.14), Color.white.opacity(0.04)]
                                    : [Color.black.opacity(0.08), Color.black.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            colorScheme == .dark
                                ? Color.white.opacity(0.20)
                                : Color.black.opacity(0.12),
                            lineWidth: 0.6
                        )
                )
        }
    }
    
    @ViewBuilder
    private var iconView: some View {
        switch state {
        case .empty:
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(colorScheme == .dark
                                 ? Color.white.opacity(0.30)
                                 : Color.black.opacity(0.30))
            
        case .ready:
            Image(systemName: "arrow.up")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .darkBase : .lightBase)
            
        case .processing:
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(colorScheme == .dark
                                 ? Color.white.opacity(0.50)
                                 : Color.black.opacity(0.40))
                .symbolEffect(.variableColor.iterative, options: .repeat(.continuous))
            
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary)
        }
    }
}

#Preview("Send Button States") {
    HStack(spacing: 24) {
        VStack {
            SendButton(state: .constant(.empty), action: {})
            Text("Empty").font(.caption).foregroundStyle(.white.opacity(0.5))
        }
        VStack {
            SendButton(state: .constant(.ready), action: {})
            Text("Ready").font(.caption).foregroundStyle(.white.opacity(0.5))
        }
        VStack {
            SendButton(state: .constant(.processing), action: {})
            Text("Processing").font(.caption).foregroundStyle(.white.opacity(0.5))
        }
        VStack {
            SendButton(state: .constant(.done), action: {})
            Text("Done").font(.caption).foregroundStyle(.white.opacity(0.5))
        }
    }
    .padding(48)
    .background(AmbientBackground())
    .preferredColorScheme(.dark)
}
