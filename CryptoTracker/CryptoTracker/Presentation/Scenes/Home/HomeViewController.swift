import UIKit
import Combine

final class HomeViewController: UIViewController {
    var viewModel: HomeViewModel!

    // UI
    private let titleLabel = UILabel()
    private let sortButton = UIButton()
    private let filterButton = UIButton()
    private let searchView = SearchView()
    private let refreshControl = UIRefreshControl()
    private let tableView = UITableView()
    private let noCoinsFoundTitleLabel = UILabel()
    private let noCoinsFoundSubTitleLabel = UILabel()
    private let errorTitleLabel = UILabel()
    private let errorSubtitleLabel = UILabel()
    private let activityIndicatorView = UIActivityIndicatorView()

    lazy private var tapOnViewGesture = UITapGestureRecognizer(
        target: self,
        action: #selector(onTouch))
    lazy private var tapOnTableViewGesture = UITapGestureRecognizer(
        target: self,
        action: #selector(onTouch))

    // Combine
    private let cancelBag = CancelBag()
    private let didLoad = PassthroughSubject<Void, Never>()
    private let refreshTrigger = PassthroughSubject<Void, Never>()
    private let didReachBottom = PassthroughSubject<Void, Never>()
    private let sortTrigger = PassthroughSubject<Void, Never>()
    private let filterTrigger = PassthroughSubject<Void, Never>()
    private let favoriteAtIndexPathTrigger = PassthroughSubject<IndexPath, Never>()

    // Data
    private var coinModels: [CoinModel] = []
    private var isKeyboardShown = false

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
        subscribe()
    }
}

// MARK: - ViewModel Binding
private extension HomeViewController {
    func bindViewModel(_ viewModel: HomeViewModel) {
        let input = HomeViewModel.Input(
            didLoad: didLoad.eraseToAnyPublisher(),
            refreshTrigger: refreshTrigger,
            didReachBottom: didReachBottom.eraseToAnyPublisher(),
            searchTextDidChangeTrigger: searchView.searchTextDidChangeTrigger.eraseToAnyPublisher(),
            sortTrigger: sortTrigger.eraseToAnyPublisher(),
            filterTrigger: filterTrigger.eraseToAnyPublisher(),
            favoriteAtIndexPathTrigger: favoriteAtIndexPathTrigger.eraseToAnyPublisher()
        )

        let output = viewModel.transform(
            input: input,
            cancelBag: cancelBag
        )
        render(output: output)
    }

    func render(output: HomeViewModel.Output) {
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

                self.refreshControl.endRefreshing()
                self.coinModels = coinModels
                if coinModels.isEmpty && isKeyboardShown {
                    self.sortButton.isHidden = true
                    self.filterButton.isHidden = true
                    self.errorTitleLabel.isHidden = true
                    self.errorSubtitleLabel.isHidden = true
                    self.searchView.isHidden = false
                    self.tableView.isHidden = true
                    self.noCoinsFoundTitleLabel.isHidden = false
                    self.noCoinsFoundSubTitleLabel.isHidden = false
                } else if coinModels.isEmpty {
                    self.sortButton.isHidden = true
                    self.filterButton.isHidden = true
                    self.errorTitleLabel.isHidden = false
                    self.errorSubtitleLabel.isHidden = false
                    self.searchView.isHidden = true
                    self.tableView.isHidden = true
                    self.noCoinsFoundTitleLabel.isHidden = true
                    self.noCoinsFoundSubTitleLabel.isHidden = true
                } else {
                    self.sortButton.isHidden = false
                    self.filterButton.isHidden = false
                    self.errorTitleLabel.isHidden = true
                    self.errorSubtitleLabel.isHidden = true
                    self.searchView.isHidden = false
                    self.tableView.isHidden = false
                    self.tableView.reloadData()
                    self.noCoinsFoundTitleLabel.isHidden = true
                    self.noCoinsFoundSubTitleLabel.isHidden = true
                }
            }
            .store(in: cancelBag)
    }
}

// MARK: - Configure UI
private extension HomeViewController {
    func addSubviews() {
        view.addSubview(titleLabel)
        view.addSubview(sortButton)
        view.addSubview(filterButton)
        view.addSubview(searchView)
        view.addSubview(tableView)
        view.addSubview(noCoinsFoundTitleLabel)
        view.addSubview(noCoinsFoundSubTitleLabel)
        view.addSubview(errorTitleLabel)
        view.addSubview(errorSubtitleLabel)
    }

    func setConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            $0.leading.equalToSuperview().offset(16)
        }

        filterButton.snp.makeConstraints {
            $0.size.equalTo(24)
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(titleLabel.snp.centerY)
        }

        sortButton.snp.makeConstraints {
            $0.size.equalTo(24)
            $0.trailing.equalTo(filterButton.snp.leading).offset(-8)
            $0.centerY.equalTo(filterButton.snp.centerY)
        }

        searchView.snp.makeConstraints {
            $0.height.equalTo(44)
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(searchView.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-20)
        }

        noCoinsFoundTitleLabel.snp.makeConstraints {
            $0.top.equalTo(searchView.snp.bottom).offset(30)
            $0.leading.equalToSuperview().offset(32)
            $0.trailing.equalToSuperview().offset(-32)
        }

        noCoinsFoundSubTitleLabel.snp.makeConstraints {
            $0.top.equalTo(noCoinsFoundTitleLabel.snp.bottom).offset(10)
            $0.leading.equalToSuperview().offset(32)
            $0.trailing.equalToSuperview().offset(-32)
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
        titleLabel.text = "Crypto Coins"
        titleLabel.font = .systemFont(ofSize: 32, weight: .heavy)
        titleLabel.textColor = .black

        // sortButton
        sortButton.isHidden = true
        sortButton.setImage(UIImage(systemName: "arrow.up.arrow.down"), for: .normal)
        sortButton.setImage(UIImage(systemName: "arrow.up.arrow.down"), for: .highlighted)
        sortButton.addAction(UIAction(handler: { [weak self] _ in
            guard let self else {
                return
            }

            self.sortTrigger.send()
        }), for: .touchUpInside)

        // filterButton
        filterButton.isHidden = true
        filterButton.setImage(UIImage(systemName: "line.3.horizontal.decrease"), for: .normal)
        filterButton.setImage(UIImage(systemName: "line.3.horizontal.decrease"), for: .highlighted)
        filterButton.addAction(UIAction(handler: { [weak self] _ in
            guard let self else {
                return
            }

            self.filterTrigger.send()
        }), for: .touchUpInside)

        // searchView
        searchView.isHidden = true

        // refreshControl
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)

        // tableView
        tableView.backgroundColor = .clear
        tableView.register(
            HomeCoinTableViewCell.self,
            forCellReuseIdentifier: HomeCoinTableViewCell.reuseId
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

        // emptySearchLabel
        noCoinsFoundTitleLabel.text = "No Matching Coins"
        noCoinsFoundTitleLabel.textAlignment = .center
        noCoinsFoundTitleLabel.textColor = .black
        noCoinsFoundTitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        noCoinsFoundTitleLabel.numberOfLines = 0
        noCoinsFoundTitleLabel.isHidden = true

        // noPlacesFoundLabel
        noCoinsFoundSubTitleLabel.text = "Make sure your query is correct or try to find a different coins."
        noCoinsFoundSubTitleLabel.textAlignment = .center
        noCoinsFoundSubTitleLabel.textColor = .black.withAlphaComponent(0.5)
        noCoinsFoundSubTitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        noCoinsFoundSubTitleLabel.numberOfLines = 0
        noCoinsFoundSubTitleLabel.isHidden = true

        // emptyTitleLabel
        errorTitleLabel.text = "Ooopps..."
        errorTitleLabel.textAlignment = .center
        errorTitleLabel.textColor = .black
        errorTitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        errorTitleLabel.numberOfLines = 0
        errorTitleLabel.isHidden = true

        // emptyDescriptionLabel
        errorSubtitleLabel.text = "Something went wrong. Please Try Again."
        errorSubtitleLabel.textAlignment = .center
        errorSubtitleLabel.textColor = .black.withAlphaComponent(0.5)
        errorSubtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        errorSubtitleLabel.numberOfLines = 0
        errorSubtitleLabel.isHidden = true

        // activityIndicatorView
        activityIndicatorView.style = .medium
        activityIndicatorView.color = .black
        activityIndicatorView.hidesWhenStopped = true
    }

    func subscribe() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification, object: nil)
            .sink { [unowned self] _ in
                self.view.addGestureRecognizer(self.tapOnViewGesture)
                self.tableView.addGestureRecognizer(self.tapOnTableViewGesture)
                self.tableView.setEditing(false, animated: true)
                self.isKeyboardShown = true
            }
            .store(in: cancelBag)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification, object: nil)
            .sink { [unowned self] _ in
                self.view.removeGestureRecognizer(self.tapOnViewGesture)
                self.tableView.removeGestureRecognizer(self.tapOnTableViewGesture)
                self.isKeyboardShown = false
            }
            .store(in: cancelBag)
    }
}

// MARK: - UITableViewDataSource
extension HomeViewController: UITableViewDataSource {
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

    func tableView
    (
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: HomeCoinTableViewCell.reuseId,
                for: indexPath
            ) as? HomeCoinTableViewCell
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
extension HomeViewController: UITableViewDelegate {
    func tableView
    (
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
//        didSelectPlaceTrigger.send(indexPath)
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

private extension HomeViewController {
    @objc func onTouch() {
        view.endEditing(true)
    }

    @objc func handleRefresh() {
        refreshTrigger.send()
    }
}
