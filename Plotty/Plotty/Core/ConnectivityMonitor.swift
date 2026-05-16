import Foundation
import Network
import SwiftUI

// MARK: - ネットワーク接続監視（オンライン必須の UI 用）
@Observable
final class ConnectivityMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "plotty.connectivity")
    
    private(set) var isOnline = true
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

private struct ConnectivityMonitorKey: EnvironmentKey {
    static let defaultValue = ConnectivityMonitor()
}

extension EnvironmentValues {
    var connectivity: ConnectivityMonitor {
        get { self[ConnectivityMonitorKey.self] }
        set { self[ConnectivityMonitorKey.self] = newValue }
    }
}
