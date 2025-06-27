import UIKit
import Combine

final class HomeViewController: UIViewController {
    var viewModel: HomeViewModel!

    // UI
    private let titleLabel = UILabel()
    private let searchView = SearchView()
    private let refreshControl = UIRefreshControl()
    private let tableView = UITableView()
    private let emptySearchLabel = UILabel()
    private let noPlacesFoundLabel = UILabel()
    private let emptyTitleLabel = UILabel()
    private let emptyDescriptionLabel = UILabel()
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
            refreshTrigger: refreshTrigger.eraseToAnyPublisher(),
            didReachBottom: didReachBottom.eraseToAnyPublisher()
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

                if isLoading {
                    activityIndicatorView.startAnimating()
                } else {
                    activityIndicatorView.stopAnimating()
                }
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
                    self.emptyTitleLabel.isHidden = true
                    self.emptyDescriptionLabel.isHidden = true
                    self.searchView.isHidden = false
                    self.tableView.isHidden = true
                    self.emptySearchLabel.isHidden = false
                    self.noPlacesFoundLabel.isHidden = false
                } else if coinModels.isEmpty {
                    self.emptyTitleLabel.isHidden = false
                    self.emptyDescriptionLabel.isHidden = false
                    self.searchView.isHidden = true
                    self.tableView.isHidden = true
                    self.emptySearchLabel.isHidden = true
                    self.noPlacesFoundLabel.isHidden = true
                } else {
                    self.emptyTitleLabel.isHidden = true
                    self.emptyDescriptionLabel.isHidden = true
                    self.searchView.isHidden = false
                    self.tableView.isHidden = false
                    self.tableView.reloadData()
                    self.emptySearchLabel.isHidden = true
                    self.noPlacesFoundLabel.isHidden = true
                }
            }
            .store(in: cancelBag)
    }
}

// MARK: - Configure UI
private extension HomeViewController {
    func addSubviews() {
        view.addSubview(titleLabel)
        view.addSubview(searchView)
        view.addSubview(tableView)
        view.addSubview(emptySearchLabel)
        view.addSubview(noPlacesFoundLabel)
        view.addSubview(emptyTitleLabel)
        view.addSubview(emptyDescriptionLabel)
        view.addSubview(activityIndicatorView)
    }

    func setConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            $0.leading.equalToSuperview().offset(16)
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

        emptySearchLabel.snp.makeConstraints {
            $0.top.equalTo(searchView.snp.bottom).offset(30)
            $0.leading.equalToSuperview().offset(32)
            $0.trailing.equalToSuperview().offset(-32)
        }

        noPlacesFoundLabel.snp.makeConstraints {
            $0.top.equalTo(emptySearchLabel.snp.bottom).offset(10)
            $0.leading.equalToSuperview().offset(32)
            $0.trailing.equalToSuperview().offset(-32)
        }

        emptyTitleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.equalToSuperview().offset(32)
            $0.trailing.equalToSuperview().offset(-32)
        }

        emptyDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(emptyTitleLabel.snp.bottom).offset(10)
            $0.leading.equalToSuperview().offset(32)
            $0.trailing.equalToSuperview().offset(-32)
        }

        activityIndicatorView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.height.width.equalTo(44)
        }
    }

    func configureViews() {
        // view
        view.backgroundColor = .white

        // titleLabel
        titleLabel.text = "Crypto Coins"
        titleLabel.font = .systemFont(ofSize: 32, weight: .heavy)
        titleLabel.textColor = .black

        // searchView
        searchView.isHidden = true

        // refreshControl
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)

        // tableView
        tableView.backgroundColor = .clear
        tableView.register(
            CoinTableViewCell.self,
            forCellReuseIdentifier: CoinTableViewCell.reuseId
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
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        tableView.refreshControl = refreshControl

        // emptySearchLabel
        emptySearchLabel.text = "No Matching Coins"
        emptySearchLabel.textAlignment = .center
        emptySearchLabel.textColor = .black
        emptySearchLabel.font = .systemFont(ofSize: 16, weight: .medium)
        emptySearchLabel.numberOfLines = 0
        emptySearchLabel.isHidden = true

        // noPlacesFoundLabel
        noPlacesFoundLabel.text = "Make sure your query is correct or try to find a different coins."
        noPlacesFoundLabel.textAlignment = .center
        noPlacesFoundLabel.textColor = .black.withAlphaComponent(0.5)
        noPlacesFoundLabel.font = .systemFont(ofSize: 14, weight: .regular)
        noPlacesFoundLabel.numberOfLines = 0
        noPlacesFoundLabel.isHidden = true

        // emptyTitleLabel
        emptyTitleLabel.text = "Ooopps..."
        emptyTitleLabel.textAlignment = .center
        emptyTitleLabel.textColor = .black
        emptyTitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        emptyTitleLabel.numberOfLines = 0
        emptyTitleLabel.isHidden = true

        // emptyDescriptionLabel
        emptyDescriptionLabel.text = "Currently no coins found."
        emptyDescriptionLabel.textAlignment = .center
        emptyDescriptionLabel.textColor = .black.withAlphaComponent(0.5)
        emptyDescriptionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        emptyDescriptionLabel.numberOfLines = 0
        emptyDescriptionLabel.isHidden = true

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
                withIdentifier: CoinTableViewCell.reuseId,
                for: indexPath
            ) as? CoinTableViewCell
        else {
            return UITableViewCell()
        }

        let coinModel = coinModels[indexPath.section]
        cell.bind(with: coinModel)

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

    func scrollViewDidScroll
    (
        _ scrollView: UIScrollView
    ) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height

        if offsetY > contentHeight - height * 1.5 {
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
