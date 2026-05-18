import Foundation

// MARK: - 端末のディスプレイ角丸（機種 ID と画面サイズから自動判定）
/// ScreenCorners 等の公開値を参考にしたマップ。未登録機種は画面短辺から推定する。
enum PlotDeviceDisplayMetrics {
    /// `uname` の machine フィールド（例: `iPhone18,1`）
    static let machineIdentifier: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }()
    
    /// AI 画面枠など、物理ディスプレイの角丸に合わせる半径（pt）
    static func displayCornerRadius(for screenSize: CGSize) -> CGFloat {
        if let mapped = Self.knownCornerRadiusByMachine[machineIdentifier] {
            return mapped
        }
        if let family = Self.familyPrefixRadius(for: machineIdentifier) {
            return family
        }
        return Self.estimatedCornerRadius(for: screenSize)
    }
    
    // MARK: - 機種別（ScreenCorners / Apple 系ディスプレイに近い値）
    
    private static let knownCornerRadiusByMachine: [String: CGFloat] = [
        // iPhone 17 系（ユーザー報告・ScreenCorners 62pt クラス）
        "iPhone18,1": 62,
        "iPhone18,2": 62,
        "iPhone18,3": 62,
        "iPhone18,4": 62,
        // iPhone 16 系
        "iPhone17,1": 55,
        "iPhone17,2": 55,
        "iPhone17,3": 47,
        "iPhone17,4": 47,
        // iPhone 15 系
        "iPhone16,1": 55,
        "iPhone16,2": 55,
        "iPhone15,4": 47,
        "iPhone15,5": 47,
        // iPhone 14 Pro 系
        "iPhone15,2": 55,
        "iPhone15,3": 55,
        // シミュレータ汎用
        "x86_64": 55,
        "arm64": 55,
        "i386": 47
    ]
    
    /// `iPhone18,*` などプレフィックス一致（未発売・将来 ID 用）
    private static func familyPrefixRadius(for identifier: String) -> CGFloat? {
        if identifier.hasPrefix("iPhone18") { return 62 }
        return nil
    }
    
    /// 論理画面サイズから Pro / Max を推定
    private static func estimatedCornerRadius(for size: CGSize) -> CGFloat {
        let width = min(size.width, size.height)
        let height = max(size.width, size.height)
        
        if width >= 440 || height >= 920 { return 62 }
        if width >= 402 { return 60 }
        if width >= 393 { return 55 }
        if width >= 375 { return 47 }
        return 42
    }
}
