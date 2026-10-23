
import Foundation
import CoreLocation

// MARK: - Offline GPS Point Model

struct YashswiOfflineLocationPoint: Codable {
    let id: UUID
    let employeeId: String
    let latitude: Double
    let longitude: Double
    let timestamp: Date
}

// MARK: - Offline GPS Storage

final class YashswiOfflineLocationStore {

    static let shared = YashswiOfflineLocationStore()

    private let storageKey = "yashswi.offline.gps.points"
    private let maximumPoints = 1000

    private init() {}

    // MARK: - Store Errors

    enum StoreError: LocalizedError {
        case invalidEmployee
        case invalidLocation
        case encodingFailed
        case storageFailed
        case storageLimitReached

        var errorDescription: String? {
            switch self {
            case .invalidEmployee:
                return "Employee ID is missing."

            case .invalidLocation:
                return "Invalid GPS coordinates."

            case .encodingFailed:
                return "Unable to encode offline GPS data."

            case .storageFailed:
                return "Unable to save offline GPS data securely."

            case .storageLimitReached:
                return "Offline GPS storage is full. Existing records have been preserved."
            }
        }
    }

    // MARK: - Read Errors

    enum ReadError: LocalizedError {
        case corruptedData

        var errorDescription: String? {
            switch self {
            case .corruptedData:
                return "Stored GPS data could not be decoded. Existing records have been preserved."
            }
        }
    }

    // MARK: - Safe Offline Data Reading

    func readPendingPoints() -> Result<
        [YashswiOfflineLocationPoint],
        Error
    > {
        let result = KeychainHelper.shared.readWithStatus(
            forKey: storageKey
        )

        switch result {
        case .success(let data):
            do {
                let points = try JSONDecoder().decode(
                    [YashswiOfflineLocationPoint].self,
                    from: data
                )

                return .success(points)

            } catch {
                return .failure(ReadError.corruptedData)
            }

        case .failure(let error):
            switch error {
            case .itemNotFound:
                return .success([])

            case .unexpectedData, .securityError:
                return .failure(error)
            }
        }
    }

    // MARK: - Legacy Read Compatibility

    // Retained for compatibility with existing callers.
    // Do not use this method for saving, deleting,
    // or synchronization decisions because it returns
    // an empty array when reading fails.

    func pendingPoints() -> [YashswiOfflineLocationPoint] {
        switch readPendingPoints() {
        case .success(let points):
            return points

        case .failure(let error):
            print(
                "Offline GPS data could not be read: \(error.localizedDescription)"
            )
            return []
        }
    }

    // MARK: - Save GPS Location

    @discardableResult
    func saveLocation(
        _ location: CLLocation,
        employeeId: String
    ) -> Result<Void, Error> {

        guard !employeeId.isEmpty else {
            return .failure(StoreError.invalidEmployee)
        }

        guard CLLocationCoordinate2DIsValid(
            location.coordinate
        ), location.horizontalAccuracy >= 0 else {
            return .failure(StoreError.invalidLocation)
        }

        let point = YashswiOfflineLocationPoint(
            id: UUID(),
            employeeId: employeeId,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: location.timestamp
        )

        // Read existing records safely.
        let pointsResult = readPendingPoints()

        var points: [YashswiOfflineLocationPoint]

        switch pointsResult {
        case .success(let existingPoints):
            points = existingPoints

        case .failure(let error):
            return .failure(error)
        }

        // Do not silently delete older GPS records.
        guard points.count < maximumPoints else {
            return .failure(StoreError.storageLimitReached)
        }

        points.append(point)

        return persist(points)
    }

    // MARK: - Remove Point By ID

    // Compatibility method retained for existing callers.
    // Prefer removePoint(id:employeeId:) for sync operations.

    @discardableResult
    func removePoint(
        id: UUID
    ) -> Result<Void, Error> {
        switch readPendingPoints() {
        case .success(var points):
            points.removeAll { $0.id == id }
            return persist(points)

        case .failure(let error):
            return .failure(error)
        }
    }

    // MARK: - Employee-Specific Point Removal

    // Only removes a record whose ID and employee ID match.
    // Call only after the backend confirms acceptance.

    @discardableResult
    func removePoint(
        id: UUID,
        employeeId: String
    ) -> Result<Void, Error> {

        guard !employeeId.isEmpty else {
            return .failure(StoreError.invalidEmployee)
        }

        switch readPendingPoints() {
        case .success(let points):

            guard let point = points.first(where: {
                $0.id == id && $0.employeeId == employeeId
            }) else {
                // No matching record found.
                // Leave all existing records unchanged.
                return .success(())
            }

            let updatedPoints = points.filter {
                $0.id != point.id
            }

            return persist(updatedPoints)

        case .failure(let error):
            return .failure(error)
        }
    }

    // MARK: - Clear All Offline GPS Records

    // Explicit destructive operation.
    // Do not call automatically during logout.

    @discardableResult
    func clearAll() -> Result<Void, Error> {
        let deleted = KeychainHelper.shared.delete(
            forKey: storageKey
        )

        return deleted
            ? .success(())
            : .failure(StoreError.storageFailed)
    }

    // MARK: - Persist GPS Records

    private func persist(
        _ points: [YashswiOfflineLocationPoint]
    ) -> Result<Void, Error> {

        guard let data = try? JSONEncoder().encode(points) else {
            return .failure(StoreError.encodingFailed)
        }

        guard KeychainHelper.shared.save(
            data,
            forKey: storageKey
        ) else {
            return .failure(StoreError.storageFailed)
        }

        return .success(())
    }
}
