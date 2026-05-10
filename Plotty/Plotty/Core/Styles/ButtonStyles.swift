import SwiftUI

// MARK: - Button Size
enum ButtonSize {
    case xl    // 56pt height - Main CTA
    case lg    // 50pt height - Section main action
    case md    // 44pt height - HIG minimum tap target (standard)
    case sm    // 36pt height - Secondary action
    case xs    // 28pt height - Chips, tags, inline only
    
    var height: CGFloat {
        switch self {
        case .xl: return 56
        case .lg: return 50
        case .md: return 44
        case .sm: return 36
        case .xs: return 28
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .xl: return 28
        case .lg: return 24
        case .md: return 20
        case .sm: return 16
        case .xs: return 12
        }
    }
    
    var font: Font {
        switch self {
        case .xl, .lg, .md: return .system(size: 17, weight: .semibold)
        case .sm: return .system(size: 13, weight: .medium)
        case .xs: return .system(size: 12, weight: .medium)
        }
    }
}

// MARK: - Button Style Type
enum ButtonStyleType {
    case filled      // Primary action
    case tinted      // Cancel, secondary
    case glass       // On layered elements
    case outline     // Alternative action
    case destructive // Delete (red exception allowed)
    case plain       // Skip, etc.
}

// MARK: - Filled Button Style
struct FilledButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    var size: ButtonSize = .md
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(colorScheme == .dark ? .darkBase : .lightBase)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(isEnabled
                          ? (colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary)
                          : (colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.12)))
            )
            .opacity(isEnabled ? 1.0 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.quick, value: configuration.isPressed)
    }
}

// MARK: - Tinted Button Style
struct TintedButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    var size: ButtonSize = .md
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(colorScheme == .dark ? .darkTextPrimary : .lightTextPrimary)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.10)
                          : Color.black.opacity(0.06))
            )
            .opacity(isEnabled ? 1.0 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.quick, value: configuration.isPressed)
    }
}

// MARK: - Glass Button Style
struct GlassButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    var size: ButtonSize = .md
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(colorScheme == .dark ? .darkTextPrimary : .lightTextPrimary)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(colorScheme == .dark
                                  ? Color.white.opacity(0.07)
                                  : Color.black.opacity(0.045))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .strokeBorder(colorScheme == .dark
                                          ? Color.white.opacity(0.14)
                                          : Color.black.opacity(0.10), lineWidth: 0.5)
                    )
            )
            .opacity(isEnabled ? 1.0 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.quick, value: configuration.isPressed)
    }
}

// MARK: - Outline Button Style
struct OutlineButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    var size: ButtonSize = .md
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(colorScheme == .dark ? .darkTextPrimary : .lightTextPrimary)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(colorScheme == .dark
                                  ? Color.white.opacity(0.22)
                                  : Color.black.opacity(0.13), lineWidth: 1.5)
            )
            .opacity(isEnabled ? 1.0 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.quick, value: configuration.isPressed)
    }
}

// MARK: - Destructive Button Style
struct DestructiveButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    var size: ButtonSize = .md
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(Color.red.opacity(0.90))
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.08)
                          : Color.black.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .strokeBorder(Color.red.opacity(0.50), lineWidth: 1)
                    )
            )
            .opacity(isEnabled ? 1.0 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.quick, value: configuration.isPressed)
    }
}

// MARK: - Plain Button Style
struct PlainTextButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    var size: ButtonSize = .md
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(colorScheme == .dark ? .darkTextPrimary : .lightTextPrimary)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .opacity(isEnabled ? 1.0 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.quick, value: configuration.isPressed)
    }
}

// MARK: - Icon Button Styles
struct CircleIconButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    enum Size {
        case lg  // 52×52
        case md  // 44×44
        case sm  // 36×36
        
        var dimension: CGFloat {
            switch self {
            case .lg: return 52
            case .md: return 44
            case .sm: return 36
            }
        }
    }
    
    var size: Size = .md
    var filled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size.dimension, height: size.dimension)
            .background(
                Circle()
                    .fill(filled
                          ? (colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary)
                          : .clear)
            )
            .overlay(
                Circle()
                    .strokeBorder(colorScheme == .dark
                                  ? Color.white.opacity(0.14)
                                  : Color.black.opacity(0.10), lineWidth: filled ? 0 : 0.5)
            )
            .foregroundColor(filled
                             ? (colorScheme == .dark ? .darkBase : .lightBase)
                             : (colorScheme == .dark ? .darkTextPrimary : .lightTextPrimary))
            .opacity(isEnabled ? 1.0 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.quick, value: configuration.isPressed)
    }
}

struct GlassIconButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    var dimension: CGFloat = 44
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: dimension, height: dimension)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .fill(colorScheme == .dark
                                  ? Color.white.opacity(0.07)
                                  : Color.black.opacity(0.045))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(colorScheme == .dark
                                          ? Color.white.opacity(0.14)
                                          : Color.black.opacity(0.10), lineWidth: 0.5)
                    )
            )
            .foregroundColor(colorScheme == .dark ? .darkTextPrimary : .lightTextPrimary)
            .opacity(isEnabled ? 1.0 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.quick, value: configuration.isPressed)
    }
}

// MARK: - View Extensions
extension View {
    func filledButtonStyle(size: ButtonSize = .md) -> some View {
        buttonStyle(FilledButtonStyle(size: size))
    }
    
    func tintedButtonStyle(size: ButtonSize = .md) -> some View {
        buttonStyle(TintedButtonStyle(size: size))
    }
    
    func glassButtonStyle(size: ButtonSize = .md) -> some View {
        buttonStyle(GlassButtonStyle(size: size))
    }
    
    func outlineButtonStyle(size: ButtonSize = .md) -> some View {
        buttonStyle(OutlineButtonStyle(size: size))
    }
    
    func destructiveButtonStyle(size: ButtonSize = .md) -> some View {
        buttonStyle(DestructiveButtonStyle(size: size))
    }
    
    func plainTextButtonStyle(size: ButtonSize = .md) -> some View {
        buttonStyle(PlainTextButtonStyle(size: size))
    }
}
