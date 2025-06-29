import UIKit
import Combine

final class FavoritesViewController: UIViewController {
    var viewModel: FavoritesViewModel!

    // UI
    private let titleLabel = UILabel()
    private let refreshControl = UIRefreshControl()
    private let tableView = UITableView()
    private let errorTitleLabel = UILabel()
    private let errorSubtitleLabel = UILabel()
    private let activityIndicatorView = UIActivityIndicatorView()

    // Combine
    private let cancelBag = CancelBag()
    private let didLoad = PassthroughSubject<Void, Never>()
    private let favoriteAtIndexPathTrigger = PassthroughSubject<IndexPath, Never>()
    private let refreshTrigger = PassthroughSubject<Void, Never>()
    private let didReachBottom = PassthroughSubject<Void, Never>()

    // Data
    private var coinModels: [CoinModel] = []

    // LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        assemble()
        bindViewModel(viewModel)
        didLoad.send()
    }

    // Assemble
    private func assemble() {
        addSubviews()
        setConstraints()
        configureViews()
    }
}

// MARK: - ViewModel Binding
private extension FavoritesViewController {
    func bindViewModel(_ viewModel: FavoritesViewModel) {
        let input = FavoritesViewModel.Input(
            didLoad: didLoad.eraseToAnyPublisher(),
            refreshTrigger: refreshTrigger.eraseToAnyPublisher(),
            didReachBottom: didReachBottom.eraseToAnyPublisher(),
            favoriteAtIndexPathTrigger: favoriteAtIndexPathTrigger.eraseToAnyPublisher()
        )

        let output = viewModel.transform(
            input: input,
            cancelBag: cancelBag
        )
        render(output: output)
    }

    func render(output: FavoritesViewModel.Output) {
        output.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                guard let self else {
                    return
                }

                isLoading ? self.activityIndicatorView.startAnimating()
                          : self.activityIndicatorView.stopAnimating()
            }
            .store(in: cancelBag)

        output.$coinModels
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coinModels in
                guard let self else {
                    return
                }

                print("🧪 VC получил coinUIModels: \(coinModels.map(\.id))")
                self.refreshControl.endRefreshing()
                self.coinModels = coinModels
                if coinModels.isEmpty {
                    self.errorTitleLabel.isHidden = false
                    self.errorSubtitleLabel.isHidden = false
                    self.tableView.isHidden = true
                } else {
                    self.errorTitleLabel.isHidden = true
                    self.errorSubtitleLabel.isHidden = true
                    self.tableView.isHidden = false
                    self.tableView.reloadData()
                }
            }
            .store(in: cancelBag)
    }
}

// MARK: - Configure UI
private extension FavoritesViewController {
    func addSubviews() {
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(errorTitleLabel)
        view.addSubview(errorSubtitleLabel)
    }

    func setConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            $0.leading.equalToSuperview().offset(16)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-20)
        }

        errorTitleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.equalToSuperview().offset(32)
            $0.trailing.equalToSuperview().offset(-32)
        }

        errorSubtitleLabel.snp.makeConstraints {
            $0.top.equalTo(errorTitleLabel.snp.bottom).offset(10)
            $0.leading.equalToSuperview().offset(32)
            $0.trailing.equalToSuperview().offset(-32)
        }
    }

    func configureViews() {
        // view
        view.backgroundColor = .white

        // titleLabel
        titleLabel.text = "Favorites Coins"
        titleLabel.font = .systemFont(ofSize: 32, weight: .heavy)
        titleLabel.textColor = .black

        // refreshControl
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)

        // tableView
        tableView.backgroundColor = .clear
        tableView.register(
            FavoritesCoinTableViewCell.self,
            forCellReuseIdentifier: FavoritesCoinTableViewCell.reuseId
        )
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionHeaderTopPadding = 0
        tableView.sectionFooterHeight = 0
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = .white
        tableView.refreshControl = refreshControl
        tableView.tableFooterView = activityIndicatorView
        activityIndicatorView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 32)

        // emptyTitleLabel
        errorTitleLabel.text = "No Favorite Coins Yet."
        errorTitleLabel.textAlignment = .center
        errorTitleLabel.textColor = .black
        errorTitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        errorTitleLabel.numberOfLines = 0
        errorTitleLabel.isHidden = true

        // emptyDescriptionLabel
        errorSubtitleLabel.text = "You can add coins to Favorite by tap on the star button."
        errorSubtitleLabel.textAlignment = .center
        errorSubtitleLabel.textColor = .black.withAlphaComponent(0.5)
        errorSubtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        errorSubtitleLabel.numberOfLines = 0
        errorSubtitleLabel.isHidden = true
    }
}

// MARK: - UITableViewDataSource
extension FavoritesViewController: UITableViewDataSource {
    func numberOfSections
    (
        in tableView: UITableView
    ) -> Int {
        return coinModels.count
    }

    func tableView
    (
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return 1
    }

    func tableView
    (
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: FavoritesCoinTableViewCell.reuseId,
                for: indexPath
            ) as? FavoritesCoinTableViewCell
        else {
            return UITableViewCell()
        }

        let coinModel = coinModels[indexPath.section]
        cell.bind(with: coinModel)

        cell.favoriteTrigger = { [weak self] in
            guard let self else {
                return
            }

            self.favoriteAtIndexPathTrigger.send(indexPath)
        }

        return cell
    }
}

// MARK: - UITableViewDelegate
extension FavoritesViewController: UITableViewDelegate {
    func tableView
    (
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }

    func tableView
    (
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        return 12
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height

        let threshold: CGFloat = 100
        if offsetY + height > contentHeight + threshold {
            didReachBottom.send()
        }
    }
}

private extension FavoritesViewController {
    @objc func handleRefresh() {
        refreshTrigger.send()
    }
}
