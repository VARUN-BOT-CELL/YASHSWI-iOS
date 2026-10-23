
import Foundation
import CoreLocation

final class YashswiLocationManager: NSObject,
    CLLocationManagerDelegate {

    // MARK: - Singleton

    static let shared = YashswiLocationManager()

    // MARK: - Core Location

    private let manager = CLLocationManager()

    private(set) var isTracking = false
    private(set) var latestLocation: CLLocation?

    // MARK: - Submission Configuration

    private let minimumSubmissionInterval: TimeInterval = 60

    private var lastSubmissionAttempt: Date?
    private var submissionInProgress = false

    // Prevent delayed callbacks from older tracking sessions
    // from changing the current tracking session.
    private var trackingSessionId = UUID()

    // Keep disabled until backend authentication,
    // attendance state and response validation are verified.
    private let automaticSubmissionEnabled = false

    // MARK: - Offline GPS Configuration

    // Record valid GPS points locally while tracking is active.
    // This does not send them to the production server.
    private let offlineRecordingEnabled = true

    // MARK: - Callbacks

    var onLocationUpdated: ((CLLocation) -> Void)?
    var onLocationError: ((Error) -> Void)?
    var onLocationDisabled: (() -> Void)?

    // MARK: - Initialization

    private override init() {
        super.init()

        manager.delegate = self

        manager.desiredAccuracy =
            kCLLocationAccuracyNearestTenMeters

        manager.distanceFilter = 25

        manager.pausesLocationUpdatesAutomatically = true

        // Background location is enabled only during
        // active tracking with Always authorization.
        manager.allowsBackgroundLocationUpdates = false

        manager.showsBackgroundLocationIndicator = true
    }

    // MARK: - Location Availability

    var isLocationAvailable: Bool {
        CLLocationManager.locationServicesEnabled() &&
        (
            manager.authorizationStatus == .authorizedWhenInUse ||
            manager.authorizationStatus == .authorizedAlways
        )
    }

    // MARK: - Permission Requests

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestBackgroundLocationPermission() {

        guard CLLocationManager.locationServicesEnabled() else {
            return
        }

        switch manager.authorizationStatus {

        case .notDetermined:
            manager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()

        case .authorizedAlways:
            break

        case .denied, .restricted:
            // Permission must be changed in iPhone Settings.
            break

        @unknown default:
            break
        }
    }

    var hasBackgroundLocationPermission: Bool {
        manager.authorizationStatus == .authorizedAlways
    }

    // MARK: - Start Tracking

    @discardableResult
    func startTracking() -> Bool {

        guard isLocationAvailable else {
            requestPermission()
            return false
        }

        // Avoid restarting an active session.
        guard !isTracking else {
            return true
        }

        let hasAlwaysPermission =
            manager.authorizationStatus == .authorizedAlways

        // Background updates also require the appropriate
        // Xcode Background Modes capability.
        manager.allowsBackgroundLocationUpdates =
            hasAlwaysPermission

        manager.showsBackgroundLocationIndicator = true

        // Create a fresh session identifier.
        trackingSessionId = UUID()

        submissionInProgress = false
        lastSubmissionAttempt = nil

        isTracking = true

        manager.startUpdatingLocation()

        return true
    }

    // MARK: - Stop Tracking

    func stopTracking() {

        manager.stopUpdatingLocation()

        manager.allowsBackgroundLocationUpdates = false

        isTracking = false

        // Invalidate delayed responses from old sessions.
        trackingSessionId = UUID()

        submissionInProgress = false
        lastSubmissionAttempt = nil

        // Do not delete saved offline GPS points.
    }

    // MARK: - Request Current Location

    func requestCurrentLocation() {

        guard isLocationAvailable else {
            requestPermission()
            return
        }

        manager.requestLocation()
    }

    // MARK: - Controlled GPS Submission

    private func submitLocationIfNeeded(
        _ location: CLLocation
    ) {

        // Production GPS submission remains disabled.
        guard automaticSubmissionEnabled else {
            return
        }

        guard isTracking else {
            return
        }

        // Prevent overlapping submissions.
        guard !submissionInProgress else {
            return
        }

        if let lastAttempt = lastSubmissionAttempt,
           Date().timeIntervalSince(lastAttempt) <
                minimumSubmissionInterval {
            return
        }

        guard let employeeId =
            AppSession.shared.authenticatedEmployeeId,
            !employeeId.isEmpty else {
            return
        }

        let sessionId = trackingSessionId

        submissionInProgress = true
        lastSubmissionAttempt = Date()

        YashswiTrackingApi.shared.sendLocation(location) {
            [weak self] result in

            DispatchQueue.main.async {

                guard let self = self else {
                    return
                }

                // Ignore responses from previous sessions.
                guard self.trackingSessionId == sessionId else {
                    return
                }

                self.submissionInProgress = false

                switch result {

                case .success:
                    // Never delete offline GPS points here.
                    // Server acknowledgment must be verified.
                    break

                case .failure(let error):
                    print(
                        "GPS submission failed: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    // MARK: - Offline GPS Recording

    private func recordLocationForOfflineQueue(
        _ location: CLLocation
    ) {

        guard offlineRecordingEnabled else {
            return
        }

        // Only record during active attendance tracking.
        guard isTracking else {
            return
        }

        guard let employeeId =
            AppSession.shared.authenticatedEmployeeId,
            !employeeId.isEmpty else {
            return
        }

        // Validate the coordinate and GPS accuracy.
        guard CLLocationCoordinate2DIsValid(
            location.coordinate
        ),
        location.horizontalAccuracy >= 0,
        location.horizontalAccuracy <= 100,
        abs(location.timestamp.timeIntervalSinceNow) <= 30 else {
            return
        }

        // Use the existing Keychain-backed store.
        // Do not create a second storage implementation.
        let result =
            YashswiOfflineLocationStore.shared.saveLocation(
                location,
                employeeId: employeeId
            )

        switch result {

        case .success:
            // The GPS point was accepted by local storage.
            // This does not mean it was uploaded.
            break

        case .failure(let error):
            print(
                "Offline GPS save failed: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Foreground Location Check

    func checkLocationAvailability() {

        guard isTracking else {
            return
        }

        guard !isLocationAvailable else {
            return
        }

        stopTracking()

        onLocationDisabled?()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {

        guard let location = locations.last else {
            return
        }

        // Reject invalid, inaccurate or stale coordinates.
        guard CLLocationCoordinate2DIsValid(
            location.coordinate
        ),
        location.horizontalAccuracy >= 0,
        location.horizontalAccuracy <= 100,
        abs(location.timestamp.timeIntervalSinceNow) <= 30 else {
            return
        }

        // Keep the newest valid location for one-time
        // requests and existing callbacks.
        latestLocation = location

        onLocationUpdated?(location)

        // Save locally during active tracking.
        // The offline queue retains its existing records.
        if isTracking {
            recordLocationForOfflineQueue(location)
        }

        // Does nothing while automaticSubmissionEnabled
        // remains false.
        submitLocationIfNeeded(location)
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {

        onLocationError?(error)
    }

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {

        guard isTracking else {
            return
        }

        if !isLocationAvailable {

            stopTracking()

            onLocationDisabled?()

            return
        }

        // Update background location capability
        // when authorization changes during tracking.
        manager.allowsBackgroundLocationUpdates =
            manager.authorizationStatus == .authorizedAlways
    }
}
