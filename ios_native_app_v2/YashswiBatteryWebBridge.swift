import UIKit
import WebKit

extension YashswiWebViewController {

    func batteryInformationForWebsite() -> [String: Any] {
        let manager = YashswiBatteryManager.shared

        var information: [String: Any] = [
            "charging_status": manager.chargingStatus,
            "health_percentage_available": false
        ]

        if let level = manager.batteryLevel {
            information["percentage"] = level
        } else {
            information["percentage"] = NSNull()
        }

        return information
    }
}
