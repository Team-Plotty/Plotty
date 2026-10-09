import SwiftUI

// MARK: - 認証画面（ログイン / 新規登録）で共有する見た目の部品
// 両画面の文字配置・余白・質感を揃えるため、見た目だけをここに集約する（入力値や処理は各画面が持つ）。

// MARK: - 見出し
/// 中央寄せの「Plotty」ロゴと説明文。
struct PlotAuthHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    let subtitle: String

    var body: some View {
        VStack(alignment: .center, spacing: Spacing.sm) {
            Text("Plotty")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)

            Text(subtitle)
                .font(.scaledBodyMedium())
                .foregroundStyle(PlotAuthPalette.secondary(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Spacing.lg)
    }
}

// MARK: - 入力欄
private struct PlotAuthInputFieldModifier: ViewModifier {
    /// 「前回使ったログイン方法」などを示すアクセントの枠線。
    let isHighlighted: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.md, style: .continuous)

        content
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(minHeight: 50)
            .background {
                shape
                    .fill(Color.clear)
                    .glassEffect(.regular, in: shape)
            }
            .overlay {
                if isHighlighted {
                    shape.strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 1)
                }
            }
    }
}

extension View {
    /// 認証画面の入力欄（ガラス背景・高さ 50）。
    func plotAuthInputField(isHighlighted: Bool = false) -> some View {
        modifier(PlotAuthInputFieldModifier(isHighlighted: isHighlighted))
    }
}

// MARK: - パスワード入力欄
/// 目のアイコンで表示 / 非表示を切り替えられるパスワード欄。
/// 確認用の再入力欄は置かず、表示して見直せることで入力ミスを防ぐ。
/// フォーカスや送信時の処理は呼び出し側で `.focused` / `.onSubmit` を付けて扱う。
struct PlotAuthPasswordField: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var text: String
    var placeholder: String = "パスワード"
    /// 新規登録・再設定では iOS のパスワード自動生成 / 保存の対象にする。
    var isNewPassword: Bool = false
    var isHighlighted: Bool = false

    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Group {
                if isRevealed {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textContentType(isNewPassword ? .newPassword : .password)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.scaledBodyMedium())

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .foregroundStyle(PlotAuthPalette.secondary(colorScheme))
                    .frame(minWidth: Spacing.minTouchTarget, minHeight: Spacing.minTouchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // 44pt のタップ領域を入力欄の内側余白に食い込ませ、欄の高さを他の入力欄（50pt）と揃える
            .padding(.vertical, -Spacing.sm)
            .padding(.trailing, -Spacing.sm)
            .accessibilityLabel(isRevealed ? "パスワードを隠す" : "パスワードを表示")
        }
        .plotAuthInputField(isHighlighted: isHighlighted)
    }
}

// MARK: - メインボタン
/// アクセントカラーのメインボタン（認証コードを送信 など）。ラベルの文字組みもここで揃える。
struct PlotAuthPrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    var isRecommended: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.md, style: .continuous)

        configuration.label
            .font(.scaledBodyLarge().weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                shape.fill(isEnabled ? Color.accentColor : Color.gray.opacity(0.5))
            }
            .glassEffect(isEnabled ? .regular.interactive() : .regular, in: shape)
            .overlay {
                if isRecommended, isEnabled {
                    shape.strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                }
            }
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - 「または」の区切り線
struct PlotAuthDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            line

            Text("または")
                .font(.scaledCaption())
                .foregroundStyle(PlotAuthPalette.secondary(colorScheme))
                .padding(.horizontal, Spacing.sm)

            line
        }
        .padding(.vertical, Spacing.md)
    }

    private var line: some View {
        Rectangle()
            .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1))
            .frame(height: 1)
    }
}

// MARK: - ログイン ⇄ 新規登録の切り替えリンク
struct PlotAuthSwitchLink: View {
    @Environment(\.colorScheme) private var colorScheme

    let prompt: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack {
            Text(prompt)
                .font(.scaledBodySmall())
                .foregroundStyle(PlotAuthPalette.secondary(colorScheme))

            Button(action: action) {
                Text(actionTitle)
                    .font(.scaledBodySmall().weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.md)
    }
}

// MARK: - 規約への同意（チェックボックス）
/// 文中の「利用規約」「プライバシーポリシー」はリンクとして各シートを開く。
/// リンクは独自スキームで受け取り、外部（Safari 等）には渡さない。
struct PlotTermsConsentRow: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var isAgreed: Bool
    let onShowTerms: () -> Void
    let onShowPrivacy: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.xs) {
            Button {
                isAgreed.toggle()
            } label: {
                Image(systemName: isAgreed ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isAgreed ? Color.accentColor : PlotAuthPalette.secondary(colorScheme))
                    // 左端を入力欄のラベルと揃えつつ、縦は 44pt のタップ領域を確保する
                    .frame(minWidth: 28, minHeight: Spacing.minTouchTarget, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("利用規約とプライバシーポリシーに同意する")
            .accessibilityAddTraits(isAgreed ? .isSelected : [])

            Text("[利用規約](plotty-legal://terms)と[プライバシーポリシー](plotty-legal://privacy)に同意する")
                .font(.scaledBodySmall())
                .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                .tint(Color.accentColor)
                .environment(\.openURL, OpenURLAction { url in
                    switch url.host() {
                    case "terms":
                        onShowTerms()
                        return .handled
                    case "privacy":
                        onShowPrivacy()
                        return .handled
                    default:
                        return .discarded
                    }
                })

            Spacer(minLength: 0)
        }
    }
}

// MARK: - 色
enum PlotAuthPalette {
    /// ラベルや補足文などの控えめな文字色。
    static func secondary(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var isAgreed = false

    VStack(spacing: Spacing.md) {
        PlotAuthHeader(subtitle: "アカウントを作成してはじめましょう")
        TextField("example@email.com", text: .constant(""))
            .plotAuthInputField()
        PlotAuthPasswordField(text: .constant("password"), isNewPassword: true)
        PlotTermsConsentRow(isAgreed: $isAgreed, onShowTerms: {}, onShowPrivacy: {})
        Button("登録する") {}
            .buttonStyle(PlotAuthPrimaryButtonStyle(isEnabled: isAgreed))
        PlotAuthDivider()
        PlotAuthSwitchLink(prompt: "すでにアカウントをお持ちの方", actionTitle: "ログイン") {}
    }
    .padding(Spacing.screenEdge)
    .ambientBackground()
    .preferredColorScheme(.dark)
}
#endif
