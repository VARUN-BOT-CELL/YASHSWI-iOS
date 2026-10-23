import UIKit

final class YashswiBatteryManager {

    static let shared = YashswiBatteryManager()

    private init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    var batteryLevel: Int? {
        let level = UIDevice.current.batteryLevel

        guard level >= 0 else {
            return nil
        }

        return Int((level * 100).rounded())
    }

    var chargingStatus: String {
        switch UIDevice.current.batteryState {
        case .charging:
            return "Charging"

        case .full:
            return "Fully Charged"

        case .unplugged:
            return "Not Charging"

        default:
            return "Unknown"
        }
    }

    var batteryInformation: [String: Any] {
        return [
            "percentage": batteryLevel as Any,
            "charging_status": chargingStatus,
            "health_percentage_available": false
        ]
    }
}
