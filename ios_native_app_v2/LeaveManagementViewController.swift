import UIKit

/// Native leave-request form. This version previews the request locally;
/// it does not submit to the server until the actual leave API is confirmed.
final class LeaveManagementViewController: UIViewController {

    private let leaveType = UISegmentedControl(items: ["Casual", "Sick", "Earned"])
    private let startDate = UIDatePicker()
    private let endDate = UIDatePicker()
    private let reasonField = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Leave Management"

        let backButton = UIButton(type: .system)
        backButton.setTitle("← Dashboard", for: .normal)
        backButton.contentHorizontalAlignment = .left
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)

        let titleLabel = makeLabel("Apply for Leave", size: 26, bold: true)
        let employeeName = AppSession.shared.currentUser?.name ?? "Employee"
        let employeeLabel = makeLabel("Employee: \(employeeName)", size: 15)
        employeeLabel.textColor = .secondaryLabel

        leaveType.selectedSegmentIndex = 0
        leaveType.selectedSegmentTintColor = UIColor(red: 0.26, green: 0.22, blue: 0.79, alpha: 1)
        leaveType.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)

        for picker in [startDate, endDate] {
            picker.datePickerMode = .date
            picker.preferredDatePickerStyle = .compact
            picker.minimumDate = Calendar.current.startOfDay(for: Date())
        }
        startDate.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        endDate.minimumDate = startDate.date

        reasonField.backgroundColor = .secondarySystemBackground
        reasonField.layer.cornerRadius = 12
        reasonField.font = .systemFont(ofSize: 16)
        reasonField.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        reasonField.heightAnchor.constraint(equalToConstant: 115).isActive = true
        reasonField.accessibilityLabel = "Reason for leave"

        let previewButton = UIButton(type: .system)
        previewButton.setTitle("Preview Leave Request", for: .normal)
        previewButton.setTitleColor(.white, for: .normal)
        previewButton.backgroundColor = UIColor(red: 0.12, green: 0.23, blue: 0.54, alpha: 1)
        previewButton.layer.cornerRadius = 12
        previewButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        previewButton.addTarget(self, action: #selector(previewTapped), for: .touchUpInside)

        let noticeLabel = makeLabel(
            "Preview only — your leave request will NOT be submitted. " +
            "Submission, leave balance and approval status require confirmation of the YASHSWI leave API.",
            size: 13
        )
        noticeLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [
            backButton,
            titleLabel,
            employeeLabel,
            makeLabel("Leave type", size: 15, bold: true),
            leaveType,
            makeLabel("Start date", size: 15, bold: true),
            startDate,
            makeLabel("End date", size: 15, bold: true),
            endDate,
            makeLabel("Reason", size: 15, bold: true),
            reasonField,
            previewButton,
            noticeLabel
        ])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 16
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
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])
    }

    private func makeLabel(_ text: String, size: CGFloat, bold: Bool = false) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        label.numberOfLines = 0
        return label
    }

    @objc private func startDateChanged() {
        endDate.minimumDate = startDate.date
        if endDate.date < startDate.date {
            endDate.date = startDate.date
        }
    }

    @objc private func previewTapped() {
        view.endEditing(true)
        let reason = reasonField.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reason.isEmpty else {
            showAlert("Reason required", "Please enter a reason for your leave request.")
            return
        }

        let calendar = Calendar.current
        let from = calendar.startOfDay(for: startDate.date)
        let to = calendar.startOfDay(for: endDate.date)
        guard to >= from else {
            showAlert("Invalid dates", "End date cannot be earlier than start date.")
            return
        }

        let days = (calendar.dateComponents([.day], from: from, to: to).day ?? 0) + 1
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let category = leaveType.titleForSegment(at: leaveType.selectedSegmentIndex) ?? "Leave"

        showAlert("Leave Preview — Not Submitted", """
        Type: \(category)
        From: \(formatter.string(from: from))
        To: \(formatter.string(from: to))
        Calendar days: \(days)
        Reason: \(reason)

        This is only a preview. No request has been sent to the company.
        """)
    }

    @objc private func goBack() {
        dismiss(animated: true)
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
