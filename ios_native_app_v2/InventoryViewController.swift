
import UIKit

final class InventoryViewController: UIViewController, UISearchBarDelegate {

    private struct InventoryItem {
        let name: String
        let partNumber: String
        let quantity: Int
    }

    // Sample data for UI development only
    private let items: [InventoryItem] = [
        InventoryItem(name: "Filter Assembly", partNumber: "FLT-001", quantity: 24),
        InventoryItem(name: "Motor Unit", partNumber: "MTR-002", quantity: 8),
        InventoryItem(name: "Control Board", partNumber: "PCB-003", quantity: 0),
        InventoryItem(name: "Drive Belt", partNumber: "BLT-004", quantity: 15)
    ]

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let searchBar = UISearchBar()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        displayItems(items)
    }

    private func setupUI() {
        view.backgroundColor = UIColor.systemGroupedBackground

        let titleLabel = UILabel()
        titleLabel.text = "Inventory Management"
        titleLabel.font = .boldSystemFont(ofSize: 26)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Browse spare parts and stock availability"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        let backButton = UIButton(type: .system)
        backButton.setTitle("← Back to Dashboard", for: .normal)
        backButton.addTarget(
            self,
            action: #selector(goBack),
            for: .touchUpInside
        )

        searchBar.placeholder = "Search part name or number"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stackView.axis = .vertical
        stackView.spacing = 14
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        [backButton, titleLabel, subtitleLabel, searchBar]
            .forEach { stackView.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            scrollView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            scrollView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            scrollView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),

            stackView.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor,
                constant: 20
            ),
            stackView.leadingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                constant: 20
            ),
            stackView.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                constant: -20
            ),
            stackView.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -20
            ),
            stackView.widthAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.widthAnchor,
                constant: -40
            )
        ])
    }

    private func displayItems(_ filteredItems: [InventoryItem]) {
        // Keep the first four UI components
        while stackView.arrangedSubviews.count > 4 {
            guard let lastView = stackView.arrangedSubviews.last else {
                break
            }
            stackView.removeArrangedSubview(lastView)
            lastView.removeFromSuperview()
        }

        if filteredItems.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No matching spare parts found"
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .secondaryLabel
            stackView.addArrangedSubview(emptyLabel)
            return
        }

        for item in filteredItems {
            let card = createItemCard(item)
            stackView.addArrangedSubview(card)
        }
    }

    private func createItemCard(_ item: InventoryItem) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.separator.cgColor

        let nameLabel = UILabel()
        nameLabel.text = item.name
        nameLabel.font = .boldSystemFont(ofSize: 17)
        nameLabel.textColor = .label

        let codeLabel = UILabel()
        codeLabel.text = "Part No: \(item.partNumber)"
        codeLabel.font = .systemFont(ofSize: 13)
        codeLabel.textColor = .secondaryLabel

        let quantityLabel = UILabel()
        quantityLabel.text = "Available Quantity: \(item.quantity)"
        quantityLabel.font = .systemFont(ofSize: 14, weight: .medium)

        let statusLabel = UILabel()

        if item.quantity == 0 {
            statusLabel.text = "Out of Stock"
            statusLabel.textColor = .systemRed
        } else if item.quantity < 10 {
            statusLabel.text = "Low Stock"
            statusLabel.textColor = .systemOrange
        } else {
            statusLabel.text = "In Stock"
            statusLabel.textColor = .systemGreen
        }

        statusLabel.font = .boldSystemFont(ofSize: 13)

        let content = UIStackView(arrangedSubviews: [
            nameLabel,
            codeLabel,
            quantityLabel,
            statusLabel
        ])

        content.axis = .vertical
        content.spacing = 10
        content.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(
                equalTo: card.topAnchor,
                constant: 18
            ),
            content.leadingAnchor.constraint(
                equalTo: card.leadingAnchor,
                constant: 18
            ),
            content.trailingAnchor.constraint(
                equalTo: card.trailingAnchor,
                constant: -18
            ),
            content.bottomAnchor.constraint(
                equalTo: card.bottomAnchor,
                constant: -18
            )
        ])

        return card
    }

    func searchBar(
        _ searchBar: UISearchBar,
        textDidChange searchText: String
    ) {
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if query.isEmpty {
            displayItems(items)
            return
        }

        let filtered = items.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.partNumber.localizedCaseInsensitiveContains(query)
        }

        displayItems(filtered)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    @objc private func goBack() {
        dismiss(animated: true)
    }
}
