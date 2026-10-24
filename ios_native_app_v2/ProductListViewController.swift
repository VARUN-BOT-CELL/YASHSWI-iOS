
import UIKit

final class ProductListViewController: UIViewController {

    private var products: [Product] = []
    private var filteredProducts: [Product] = []

    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadProducts()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground

        let header = UIView()
        header.backgroundColor = UIColor(
            red: 0.12,
            green: 0.23,
            blue: 0.54,
            alpha: 1
        )
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        let backButton = UIButton(type: .system)
        backButton.setTitle("‹ Dashboard", for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.addTarget(
            self,
            action: #selector(goBack),
            for: .touchUpInside
        )

        let titleLabel = UILabel()
        titleLabel.text = "Products"
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 28)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Explore the product catalogue"
        subtitleLabel.textColor = .white.withAlphaComponent(0.8)
        subtitleLabel.font = .systemFont(ofSize: 14)

        let headerStack = UIStackView(arrangedSubviews: [
            backButton,
            titleLabel,
            subtitleLabel
        ])
        headerStack.axis = .vertical
        headerStack.alignment = .leading
        headerStack.spacing = 9
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(headerStack)

        searchBar.placeholder = "Search products or categories"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 110
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            ProductCell.self,
            forCellReuseIdentifier: "ProductCell"
        )
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)

        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.isHidden = true
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerStack.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 12
            ),
            headerStack.leadingAnchor.constraint(
                equalTo: header.leadingAnchor,
                constant: 22
            ),
            headerStack.trailingAnchor.constraint(
                lessThanOrEqualTo: header.trailingAnchor,
                constant: -22
            ),
            headerStack.bottomAnchor.constraint(
                equalTo: header.bottomAnchor,
                constant: -22
            ),

            searchBar.topAnchor.constraint(
                equalTo: header.bottomAnchor,
                constant: 12
            ),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            tableView.topAnchor.constraint(
                equalTo: searchBar.bottomAnchor,
                constant: 8
            ),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),

            statusLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
    }

    private func loadProducts() {
        statusLabel.isHidden = true
        loadingIndicator.startAnimating()

        ApiService.shared.getProducts { [weak self] result in
            guard let self = self else { return }
            self.loadingIndicator.stopAnimating()

            switch result {
            case .success(let response):
                if response.success {
                    self.products = response.data
                    self.filterProducts(self.searchBar.text ?? "")
                } else {
                    self.showStatus("Unable to load products.")
                }

            case .failure(let error):
                self.showStatus(error.localizedDescription)
            }
        }
    }

    private func filterProducts(_ query: String) {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)

        filteredProducts = text.isEmpty
            ? products
            : products.filter {
                $0.name.localizedCaseInsensitiveContains(text) ||
                $0.category.localizedCaseInsensitiveContains(text)
            }

        tableView.reloadData()

        if filteredProducts.isEmpty {
            showStatus(products.isEmpty ? "No products available." : "No matching products.")
        } else {
            statusLabel.isHidden = true
        }
    }

    private func showStatus(_ message: String) {
        statusLabel.text = message
        statusLabel.isHidden = false
        tableView.reloadData()
    }

    @objc private func goBack() {
        dismiss(animated: true)
    }
}

// MARK: - Search

extension ProductListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterProducts(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - Product List

extension ProductListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredProducts.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "ProductCell",
            for: indexPath
        ) as? ProductCell else {
            assertionFailure("ProductCell registration mismatch")
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }

        cell.configure(with: filteredProducts[indexPath.row])
        return cell
    }
}

// MARK: - Product Card

final class ProductCell: UITableViewCell {

    private let productImage = UIImageView()
    private let nameLabel = UILabel()
    private let categoryLabel = UILabel()
    private let descriptionLabel = UILabel()

    private var imageTask: URLSessionDataTask?
    private var representedImageURL: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        representedImageURL = nil
        productImage.image = UIImage(systemName: "shippingbox")
    }

    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none

        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        productImage.contentMode = .scaleAspectFill
        productImage.clipsToBounds = true
        productImage.layer.cornerRadius = 10
        productImage.tintColor = .secondaryLabel
        productImage.image = UIImage(systemName: "shippingbox")
        productImage.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .boldSystemFont(ofSize: 17)
        nameLabel.numberOfLines = 2

        categoryLabel.font = .systemFont(ofSize: 13, weight: .medium)
        categoryLabel.textColor = .systemIndigo

        descriptionLabel.font = .systemFont(ofSize: 13)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 3

        let labels = UIStackView(arrangedSubviews: [
            nameLabel,
            categoryLabel,
            descriptionLabel
        ])
        labels.axis = .vertical
        labels.spacing = 7

        let horizontal = UIStackView(arrangedSubviews: [productImage, labels])
        horizontal.axis = .horizontal
        horizontal.alignment = .top
        horizontal.spacing = 14
        horizontal.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(horizontal)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            horizontal.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            horizontal.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            horizontal.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            horizontal.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),

            productImage.widthAnchor.constraint(equalToConstant: 84),
            productImage.heightAnchor.constraint(equalToConstant: 84)
        ])
    }

    func configure(with product: Product) {
        nameLabel.text = product.name
        categoryLabel.text = product.category
        descriptionLabel.text = product.description

        imageTask?.cancel()
        imageTask = nil
        productImage.image = UIImage(systemName: "shippingbox")
        representedImageURL = product.imageUrl

        guard let url = URL(string: product.imageUrl),
              url.scheme == "https" else { return }

        let expectedURL = product.imageUrl

        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard error == nil,
                  let data = data,
                  let image = UIImage(data: data) else {
                return
            }

            DispatchQueue.main.async {
                guard self?.representedImageURL == expectedURL else { return }
                self?.productImage.image = image
            }
        }

        imageTask?.resume()
    }
}
