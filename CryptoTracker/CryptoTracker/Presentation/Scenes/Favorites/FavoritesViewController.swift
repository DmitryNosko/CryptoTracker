import UIKit
import Combine

final class FavoritesViewController: UIViewController {
    var viewModel: FavoritesViewModel!

    // UI
    private let titleLabel = UILabel()
    private let tableView = UITableView()
    private let errorTitleLabel = UILabel()
    private let errorSubtitleLabel = UILabel()

    // Combine
    private let cancelBag = CancelBag()
    private let favoriteAtIndexPathTrigger = PassthroughSubject<IndexPath, Never>()
    private let didSelectCoinAtIndexPath = PassthroughSubject<IndexPath, Never>()

    // Data
    private var coinModels: [CoinModel] = []

    // LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        assemble()
        bindViewModel(viewModel)
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
            favoriteAtIndexPathTrigger: favoriteAtIndexPathTrigger.eraseToAnyPublisher(),
            didSelectCoinAtIndexPath: didSelectCoinAtIndexPath.eraseToAnyPublisher()
        )

        let output = viewModel.transform(
            input: input,
            cancelBag: cancelBag
        )
        render(output: output)
    }

    func render(output: FavoritesViewModel.Output) {
        output.$coinModels
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coinModels in

                self?.coinModels = coinModels
                if coinModels.isEmpty {
                    self?.errorTitleLabel.isHidden = false
                    self?.errorSubtitleLabel.isHidden = false
                    self?.tableView.isHidden = true
                } else {
                    self?.errorTitleLabel.isHidden = true
                    self?.errorSubtitleLabel.isHidden = true
                    self?.tableView.isHidden = false
                    self?.tableView.reloadData()
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
            ) as? FavoritesCoinTableViewCell,
            !coinModels.isEmpty
        else {
            return UITableViewCell()
        }

        let coinModel = coinModels[indexPath.section]
        cell.bind(with: coinModel)

        cell.favoriteTrigger = { [weak self] in
            guard let self else {
                return
            }

            guard
                indexPath.section >= 0 && indexPath.section < self.coinModels.count
            else {
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
    
    func tableView
    (
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        didSelectCoinAtIndexPath.send(indexPath)
    }
}
