
import Foundation
import Network

final class YashswiNetworkMonitor {

    static let shared = YashswiNetworkMonitor()

    private let monitor = NWPathMonitor()

    private let monitorQueue = DispatchQueue(
        label: "com.yashswi.network.monitor"
    )

    private(set) var isConnected = false
    private(set) var hasReceivedNetworkStatus = false

    var onConnectionChanged: ((Bool) -> Void)?

    private var isMonitoring = false

    private init() {}

    // MARK: - Start Monitoring

    func startMonitoring() {
        if Thread.isMainThread {
            startMonitoringOnMainThread()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.startMonitoringOnMainThread()
            }
        }
    }

    private func startMonitoringOnMainThread() {
        guard !isMonitoring else { return }

        isMonitoring = true

        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied

            DispatchQueue.main.async {
                guard let self = self else { return }

                let previous = self.isConnected
                let firstUpdate =
                    !self.hasReceivedNetworkStatus

                self.isConnected = connected
                self.hasReceivedNetworkStatus = true

                if firstUpdate || previous != connected {
                    self.onConnectionChanged?(connected)
                }
            }
        }

        monitor.start(queue: monitorQueue)
    }

    // MARK: - Current Status

    var isNetworkAvailable: Bool {
        hasReceivedNetworkStatus && isConnected
    }
}
