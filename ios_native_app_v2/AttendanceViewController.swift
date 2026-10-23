import UIKit
import CoreLocation

final class AttendanceViewController: UIViewController,
                                      CLLocationManagerDelegate,
                                      UIImagePickerControllerDelegate,
                                      UINavigationControllerDelegate {

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private let photoPreview = UIImageView()
    private let locationLabel = UILabel()
    private let statusLabel = UILabel()
    private let submitButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var attendancePhoto: String?
    private var currentLocation: CLLocation?
    private var currentAddress: String?
    private var isSubmitting = false
    private var submissionCompleted = false

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        setupUI()
        updateSubmitButton()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let backButton = makeButton("← Dashboard", action: #selector(goBack))
        let titleLabel = makeLabel("Employee Attendance", size: 26, bold: true)
        let employeeName = AppSession.shared.currentUser?.name ?? "Employee"
        let employeeLabel = makeLabel("Employee: \(employeeName)", size: 16)
        let instructionsLabel = makeLabel(
            "Take a live photo and get your current location before submitting attendance.",
            size: 15
        )
        instructionsLabel.textColor = .secondaryLabel

        photoPreview.backgroundColor = .secondarySystemBackground
        photoPreview.contentMode = .scaleAspectFill
        photoPreview.clipsToBounds = true
        photoPreview.layer.cornerRadius = 12
        photoPreview.translatesAutoresizingMaskIntoConstraints = false
        photoPreview.heightAnchor.constraint(equalToConstant: 200).isActive = true

        let photoButton = makeButton("1. Take Attendance Photo", action: #selector(takePhoto))
        let locationButton = makeButton("2. Get Current Location", action: #selector(getLocation))

        locationLabel.text = "Location: Not captured"
        locationLabel.numberOfLines = 0
        locationLabel.font = .systemFont(ofSize: 14)
        locationLabel.textColor = .secondaryLabel

        submitButton.setTitle("3. Submit Attendance", for: .normal)
        submitButton.addTarget(self, action: #selector(submitAttendance), for: .touchUpInside)
        submitButton.backgroundColor = UIColor(red: 0.12, green: 0.23, blue: 0.54, alpha: 1)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 10
        submitButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        statusLabel.text = "Not submitted"
        statusLabel.numberOfLines = 0
        statusLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [
            backButton,
            titleLabel,
            employeeLabel,
            instructionsLabel,
            photoPreview,
            photoButton,
            locationButton,
            locationLabel,
            submitButton,
            loadingIndicator,
            statusLabel
        ])
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])
    }

    private func makeLabel(_ title: String, size: CGFloat, bold: Bool = false) -> UILabel {
        let label = UILabel()
        label.text = title
        label.numberOfLines = 0
        label.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        return label
    }

    private func makeButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }

    @objc private func goBack() {
        dismiss(animated: true)
    }

    @objc private func takePhoto() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showMessage("Camera unavailable. This feature needs a real iPhone camera.")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = UIImagePickerController.isCameraDeviceAvailable(.front) ? .front : .rear
        picker.delegate = self
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage,
              let jpegData = image.jpegData(compressionQuality: 0.65) else {
            showMessage("Could not read the photo. Please try again.")
            return
        }
        attendancePhoto = jpegData.base64EncodedString()
        photoPreview.image = image
        statusLabel.text = "Photo captured. Get your location next."
        updateSubmitButton()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    @objc private func getLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationLabel.text = "Finding your location…"
            locationManager.requestLocation()
        case .restricted, .denied:
            showMessage("Location permission is required. Enable it in the iPhone Settings app.")
        @unknown default:
            showMessage("Unable to check location permission.")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways ||
           manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        
guard let location = locations.last else {
    return
}

let accuracy = location.horizontalAccuracy
let locationAge = abs(location.timestamp.timeIntervalSinceNow)

guard accuracy >= 0,
      accuracy <= 100,
      locationAge <= 30 else {

    currentLocation = nil
    currentAddress = nil

    locationLabel.text =
        "GPS accuracy is insufficient or location is outdated. Please try again."

    updateSubmitButton()
    return
}

        currentLocation = location
        currentAddress = nil
        locationLabel.text = "Location captured. Finding address…"
        updateSubmitButton()

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                // A coordinate fallback permits submission even when reverse geocoding fails.
                let place = placemarks?.first
                let components = [place?.name, place?.locality, place?.administrativeArea]
                    .compactMap { $0 }
                let coordinates = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
                self.currentAddress = components.isEmpty ? coordinates : components.joined(separator: ", ")
                self.locationLabel.text = "Location: \(self.currentAddress ?? coordinates)"
                self.updateSubmitButton()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationLabel.text = "Location failed: \(error.localizedDescription)"
        currentLocation = nil
        currentAddress = nil
        updateSubmitButton()
    }

    private func updateSubmitButton() {
        submitButton.isEnabled = attendancePhoto != nil &&
            currentLocation != nil && currentAddress != nil &&
            AppSession.shared.currentUser != nil && !isSubmitting && !submissionCompleted
        submitButton.alpha = submitButton.isEnabled ? 1 : 0.5
    }

    @objc private func submitAttendance() {
        guard !isSubmitting && !submissionCompleted,
              let employee = AppSession.shared.currentUser,
              let photo = attendancePhoto,
              let location = currentLocation,
              let address = currentAddress else {
            showMessage("Take a photo and capture your location first.")
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = .current

        let request = AttendanceRequest(
            empId: employee.empId,
            photo: photo,
            lat: String(location.coordinate.latitude),
            lng: String(location.coordinate.longitude),
            address: address,
            deviceTime: dateFormatter.string(from: Date())
        )

        isSubmitting = true
        loadingIndicator.startAnimating()
        statusLabel.text = "Submitting attendance to the server…"
        updateSubmitButton()

        ApiService.shared.submitAttendance(request: request) { [weak self] result in
            guard let self = self else { return }
            self.isSubmitting = false
            self.loadingIndicator.stopAnimating()

            switch result {
            case .success(let response):
                if response.success {
                    self.submissionCompleted = true
                    self.statusLabel.text = "Server confirmed (\(response.type)): \(response.message)"
                } else {
                    self.statusLabel.text = "Not submitted: \(response.message)"
                }
            case .failure(let error):
                self.statusLabel.text = "Submission not confirmed: \(error.localizedDescription). Check your attendance record before retrying."
            }
            self.updateSubmitButton()
        }
    }

    private func showMessage(_ message: String) {
        let alert = UIAlertController(title: "Attendance", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
