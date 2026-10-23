import UIKit

/// Employee FSR draft. Capture and preview only; no production API submission.
final class FSRViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let machineField = UITextField()
    private let visitTypeField = UITextField()
    private let purposeField = UITextField()
    private let hmrField = UITextField()
    private let customerIssue = UITextView()
    private let engineerIssue = UITextView()
    private let actionTaken = UITextView()
    private let partsUsed = UITextView()
    private let photoPreview = UIImageView()
    private let signaturePad = FSRSignaturePad()
    private var hmrPhoto: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        let back = makeButton("← Dashboard", selector: #selector(goBack), filled: false)
        let title = label("Field Service Report", size: 27, bold: true)
        let engineer = label("Employee: \(AppSession.shared.currentUser?.name ?? "Not signed in")", size: 14)
        engineer.textColor = .secondaryLabel

        configure(machineField, "Machine number")
        configure(visitTypeField, "Visit type")
        configure(purposeField, "Visit purpose")
        configure(hmrField, "HMR / hour meter")
        hmrField.keyboardType = .numberPad
        configure(customerIssue, "Customer reported issue")
        configure(engineerIssue, "Engineer findings")
        configure(actionTaken, "Action taken")
        configure(partsUsed, "Parts used (optional)")

        photoPreview.backgroundColor = .secondarySystemBackground
        photoPreview.contentMode = .scaleAspectFit
        photoPreview.tintColor = .secondaryLabel
        photoPreview.image = UIImage(systemName: "camera")
        photoPreview.layer.cornerRadius = 12
        photoPreview.clipsToBounds = true
        photoPreview.heightAnchor.constraint(equalToConstant: 150).isActive = true
        let photoButton = makeButton("Take HMR Photo", selector: #selector(takePhoto), filled: false)

        signaturePad.backgroundColor = .white
        signaturePad.layer.cornerRadius = 12
        signaturePad.layer.borderWidth = 1
        signaturePad.layer.borderColor = UIColor.separator.cgColor
        signaturePad.heightAnchor.constraint(equalToConstant: 170).isActive = true
        signaturePad.accessibilityLabel = "Customer signature drawing area"
        let clearButton = makeButton("Clear Signature", selector: #selector(clearSignature), filled: false)
        let preview = makeButton("Preview Report — Not Submitted", selector: #selector(previewTapped), filled: true)
        let notice = label("Draft only. Nothing is uploaded or saved to the company. The server's photo, signature and report requirements must be confirmed before submission.", size: 13)
        notice.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [
            back, title, engineer,
            label("Machine number", size: 15, bold: true), machineField,
            label("Visit type", size: 15, bold: true), visitTypeField,
            label("Visit purpose", size: 15, bold: true), purposeField,
            label("HMR", size: 15, bold: true), hmrField,
            label("Customer reported issue", size: 15, bold: true), customerIssue,
            label("Engineer findings", size: 15, bold: true), engineerIssue,
            label("Action taken", size: 15, bold: true), actionTaken,
            label("Parts used", size: 15, bold: true), partsUsed,
            label("HMR photo", size: 15, bold: true), photoPreview, photoButton,
            label("Customer signature", size: 15, bold: true), signaturePad, clearButton,
            preview, notice
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .interactive
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -22),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -44)
        ])
    }

    private func label(_ text: String, size: CGFloat, bold: Bool = false) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        l.numberOfLines = 0
        return l
    }

    private func configure(_ field: UITextField, _ placeholder: String) {
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.backgroundColor = .secondarySystemGroupedBackground
        field.autocorrectionType = .no
        field.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }

    private func configure(_ field: UITextView, _ name: String) {
        field.backgroundColor = .secondarySystemGroupedBackground
        field.layer.cornerRadius = 10
        field.font = .systemFont(ofSize: 16)
        field.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        field.heightAnchor.constraint(equalToConstant: 90).isActive = true
        field.accessibilityLabel = name
    }

    private func makeButton(_ text: String, selector: Selector, filled: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(text, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        if filled {
            button.backgroundColor = UIColor(red: 0.12, green: 0.23, blue: 0.54, alpha: 1)
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 12
        }
        button.addTarget(self, action: selector, for: .touchUpInside)
        return button
    }

    @objc private func takePhoto() {
        view.endEditing(true)
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            alert("Camera unavailable", "Use a real iPhone to capture an HMR photo.")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        defer { picker.dismiss(animated: true) }
        guard let image = info[.originalImage] as? UIImage else { return }
        hmrPhoto = image
        photoPreview.image = image
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    @objc private func clearSignature() {
        signaturePad.clear()
    }

    private func trimmed(_ value: String?) -> String {
        (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @objc private func previewTapped() {
        view.endEditing(true)
        guard AppSession.shared.currentUser != nil else {
            alert("Login required", "Please sign in before preparing a report.")
            return
        }
        let machine = trimmed(machineField.text)
        let type = trimmed(visitTypeField.text)
        let purpose = trimmed(purposeField.text)
        let customer = trimmed(customerIssue.text)
        let engineer = trimmed(engineerIssue.text)
        let action = trimmed(actionTaken.text)
        let parts = trimmed(partsUsed.text)
        guard !machine.isEmpty, !type.isEmpty, !purpose.isEmpty,
              !customer.isEmpty, !engineer.isEmpty, !action.isEmpty else {
            alert("Missing details", "Please complete all required text fields.")
            return
        }
        guard let hmr = Int(trimmed(hmrField.text)), hmr >= 0 else {
            alert("Invalid HMR", "Enter a non-negative whole-number HMR reading.")
            return
        }
        let message = """
        Machine: \(machine)
        Engineer: \(AppSession.shared.currentUser?.name ?? "")
        Visit: \(type)
        Purpose: \(purpose)
        HMR: \(hmr)
        Customer issue: \(customer)
        Engineer findings: \(engineer)
        Action: \(action)
        Parts: \(parts.isEmpty ? "None" : parts)
        HMR photo: \(hmrPhoto == nil ? "Not attached" : "Captured")
        Customer signature: \(signaturePad.hasSignature ? "Captured" : "Not added")

        Preview only — nothing submitted.
        """
        alert("FSR Preview", message)
    }

    @objc private func goBack() { dismiss(animated: true) }

    private func alert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

/// Simple touch-based signature area, held only in memory.
final class FSRSignaturePad: UIView {
    private var paths: [UIBezierPath] = []
    private var activePath: UIBezierPath?
    var hasSignature: Bool { !paths.isEmpty }

    override func draw(_ rect: CGRect) {
        UIColor.black.setStroke()
        for path in paths { path.stroke() }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        let path = UIBezierPath()
        path.lineWidth = 2.5
        path.lineCapStyle = .round
        path.move(to: point)
        path.addLine(to: point)
        paths.append(path)
        activePath = path
        setNeedsDisplay()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        activePath?.addLine(to: point)
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        activePath = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        activePath = nil
    }

    func clear() {
        paths.removeAll()
        activePath = nil
        setNeedsDisplay()
    }
}
