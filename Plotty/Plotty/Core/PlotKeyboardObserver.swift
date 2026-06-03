import SwiftUI
import Combine

// MARK: - キーボード高さ監視
/// キーボードの表示/非表示を監視し、高さを提供する（Apple標準アニメーション対応）
final class PlotKeyboardObserver: ObservableObject {
    @Published private(set) var keyboardHeight: CGFloat = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleKeyboardNotification(notification, isShowing: true)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleKeyboardNotification(notification, isShowing: false)
            }
            .store(in: &cancellables)
    }
    
    private func handleKeyboardNotification(_ notification: Notification, isShowing: Bool) {
        let userInfo = notification.userInfo
        
        // キーボードの高さを取得
        let height: CGFloat
        if isShowing,
           let frame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            height = frame.height
        } else {
            height = 0
        }
        
        // Apple標準のアニメーションパラメータを取得
        let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let curveValue = userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 7
        let curve = UIView.AnimationCurve(rawValue: Int(curveValue)) ?? .easeInOut
        
        // Apple標準のアニメーションカーブを SwiftUI Animation に変換
        let animation: Animation = switch curve {
        case .easeIn:
            .easeIn(duration: duration)
        case .easeOut:
            .easeOut(duration: duration)
        case .easeInOut:
            .easeInOut(duration: duration)
        case .linear:
            .linear(duration: duration)
        @unknown default:
            // iOS のキーボードは通常 curve 7 (keyboard curve) を使用
            .interpolatingSpring(stiffness: 500, damping: 40)
        }
        
        withAnimation(animation) {
            self.keyboardHeight = height
        }
    }
}

// MARK: - Environment Key
private struct PlotKeyboardHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var keyboardHeight: CGFloat {
        get { self[PlotKeyboardHeightKey.self] }
        set { self[PlotKeyboardHeightKey.self] = newValue }
    }
}

// MARK: - View Modifier
/// キーボードの高さを Environment に提供するモディファイア
struct PlotKeyboardAwareModifier: ViewModifier {
    @StateObject private var observer = PlotKeyboardObserver()
    
    func body(content: Content) -> some View {
        content
            .environment(\.keyboardHeight, observer.keyboardHeight)
    }
}

extension View {
    /// キーボードの高さを子ビューに提供する
    func plotKeyboardAware() -> some View {
        modifier(PlotKeyboardAwareModifier())
    }
}
