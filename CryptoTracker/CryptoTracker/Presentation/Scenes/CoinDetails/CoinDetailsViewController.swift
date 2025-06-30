import UIKit
import Combine
import SnapKit
import Kingfisher
import DGCharts

final class CoinDetailsViewController: UIViewController {
    var viewModel: CoinDetailsViewModel!

    // UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let headerView = UIView()
    private let coinImageView = UIImageView()
    private let coinNameLabel = UILabel()
    private let coinSymbolLabel = UILabel()
    private let priceLabel = UILabel()
    private let priceChangeLabel = UILabel()
    private let favoriteButton = UIButton()
    
    private let timeRangeSegmentedControl = UISegmentedControl(items: ["Day", "Week", "Month"])

    private let chartContainerView = UIView()
    private let chartView = CoinPriceChartView()
    private let chartLoadingIndicator = UIActivityIndicatorView(style: .medium)
    
    private let infoStackView = UIStackView()
    private let marketCapView = InfoRowView(title: "Рыночная капитализация")
    private let volumeView = InfoRowView(title: "Объем торгов")
    private let change24hView = InfoRowView(title: "Изменение за 24ч")
    private let high24hView = InfoRowView(title: "Максимум 24ч")
    private let low24hView = InfoRowView(title: "Минимум 24ч")
    private let circulatingSupplyView = InfoRowView(title: "Обращающееся предложение")
    private let totalSupplyView = InfoRowView(title: "Общее предложение")
    private let maxSupplyView = InfoRowView(title: "Максимальное предложение")

    // Combine
    private let cancelBag = CancelBag()
    private let didLoad = PassthroughSubject<Void, Never>()
    private let favoriteTrigger = PassthroughSubject<Void, Never>()
    private let timeRangeTrigger = PassthroughSubject<TimeRangeType, Never>()

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
private extension CoinDetailsViewController {
    func bindViewModel(_ viewModel: CoinDetailsViewModel) {
        let input = CoinDetailsViewModel.Input(
            didLoad: didLoad.eraseToAnyPublisher(),
            favoriteTrigger: favoriteTrigger.eraseToAnyPublisher(),
            timeRangeTrigger: timeRangeTrigger
        )

        let output = viewModel.transform(
            input: input,
            cancelBag: cancelBag
        )
        render(output: output)
    }

    func render(output: CoinDetailsViewModel.Output) {
        output.$coin
            .sink { [weak self] coin in
                self?.updateCoinInfo(coin)
            }
            .store(in: cancelBag)

        output.$isFavorite
            .sink { [weak self] isFavorite in
                self?.updateFavoriteButton(isFavorite)
            }
            .store(in: cancelBag)

        output.$priceHistory
            .dropFirst()
            .sink { [weak self] priceHistory in
                self?.updateChart(with: priceHistory)
            }
            .store(in: cancelBag)

        output.$isLoadingPriceHistory
            .sink { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
            }
            .store(in: cancelBag)

        output.$currentTimeRange
            .sink { [weak self] timeRange in
                self?.updateTimeRangeSelection(timeRange)
            }
            .store(in: cancelBag)
    }
}

// MARK: - Configure UI
private extension CoinDetailsViewController {
    func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerView)
        headerView.addSubview(coinImageView)
        headerView.addSubview(coinNameLabel)
        headerView.addSubview(coinSymbolLabel)
        headerView.addSubview(priceLabel)
        headerView.addSubview(priceChangeLabel)
        headerView.addSubview(favoriteButton)
        
        contentView.addSubview(timeRangeSegmentedControl)
        contentView.addSubview(chartContainerView)
        chartContainerView.addSubview(chartView)
        chartContainerView.addSubview(chartLoadingIndicator)
        
        contentView.addSubview(infoStackView)
        infoStackView.addArrangedSubview(marketCapView)
        infoStackView.addArrangedSubview(volumeView)
        infoStackView.addArrangedSubview(change24hView)
        infoStackView.addArrangedSubview(high24hView)
        infoStackView.addArrangedSubview(low24hView)
        infoStackView.addArrangedSubview(circulatingSupplyView)
        infoStackView.addArrangedSubview(totalSupplyView)
        infoStackView.addArrangedSubview(maxSupplyView)
    }

    func setConstraints() {
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(140)
        }

        coinImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(60)
        }

        coinNameLabel.snp.makeConstraints {
            $0.leading.equalTo(coinImageView.snp.trailing).offset(12)
            $0.top.equalTo(coinImageView.snp.top)
            $0.trailing.equalTo(favoriteButton.snp.leading).offset(-12)
        }

        coinSymbolLabel.snp.makeConstraints {
            $0.leading.equalTo(coinNameLabel)
            $0.top.equalTo(coinNameLabel.snp.bottom).offset(4)
        }

        priceLabel.snp.makeConstraints {
            $0.leading.equalTo(coinNameLabel)
            $0.top.equalTo(coinSymbolLabel.snp.bottom).offset(8)
        }

        priceChangeLabel.snp.makeConstraints {
            $0.leading.equalTo(priceLabel.snp.trailing).offset(12)
            $0.centerY.equalTo(priceLabel)
        }

        favoriteButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(44)
        }

        timeRangeSegmentedControl.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(32)
        }

        chartContainerView.snp.makeConstraints {
            $0.top.equalTo(timeRangeSegmentedControl.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(250)
        }

        chartView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        chartLoadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        infoStackView.snp.makeConstraints {
            $0.top.equalTo(chartContainerView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-20)
        }
    }

    func configureViews() {
        view.backgroundColor = .white

        // scrollView
        scrollView.showsVerticalScrollIndicator = false

        // headerView
        headerView.backgroundColor = .systemBackground

        // coinImageView
        coinImageView.contentMode = .scaleAspectFit
        coinImageView.layer.cornerRadius = 30
        coinImageView.clipsToBounds = true

        // coinNameLabel
        coinNameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        coinNameLabel.textColor = .label

        // coinSymbolLabel
        coinSymbolLabel.font = .systemFont(ofSize: 16, weight: .medium)
        coinSymbolLabel.textColor = .secondaryLabel

        // priceLabel
        priceLabel.font = .systemFont(ofSize: 24, weight: .bold)
        priceLabel.textColor = .label

        // priceChangeLabel
        priceChangeLabel.font = .systemFont(ofSize: 16, weight: .medium)

        // favoriteButton
        favoriteButton.addAction(UIAction(handler: { [weak self] _ in
            guard let self else {
                return
            }

            self.favoriteTrigger.send()
        }), for: .touchUpInside)

        // timeRangeSegmentedControl
        timeRangeSegmentedControl.selectedSegmentIndex = 0
        timeRangeSegmentedControl.addTarget(self, action: #selector(timeRangeDidChanged), for: .valueChanged)
        
        // chartContainerView
        chartContainerView.backgroundColor = .systemGray6
        chartContainerView.layer.cornerRadius = 12

        // chartLoadingIndicator
        chartLoadingIndicator.hidesWhenStopped = true

        // infoStackView
        infoStackView.axis = .vertical
        infoStackView.spacing = 16
        infoStackView.distribution = .fillEqually
    }
}

private extension CoinDetailsViewController {
    @objc func timeRangeDidChanged() {
        let timeRange: TimeRangeType
        switch timeRangeSegmentedControl.selectedSegmentIndex {
        case 0: timeRange = .day
        case 1: timeRange = .week
        case 2: timeRange = .month
        default: timeRange = .day
        }
        timeRangeTrigger.send(timeRange)
    }
}

// MARK: - Update Methods
private extension CoinDetailsViewController {
    func updateCoinInfo(_ coin: CoinModel) {
        coinNameLabel.text = coin.name
        coinSymbolLabel.text = coin.symbol.uppercased()
        priceLabel.text = coin.formattedPrice
        priceChangeLabel.text = coin.formattedPriceChange24h
        priceChangeLabel.textColor = coin.priceChangeColor
        coinImageView.kf.setImage(with: coin.imageURL)
        
        marketCapView.setValue(coin.formattedMarketCap)
        volumeView.setValue(coin.formattedVolume)
        change24hView.setValue(coin.formattedPriceChange24h)
        change24hView.setValueColor(coin.priceChangeColor)
        
        if let high24h = coin.high24h {
            high24hView.setValue("$\(String(format: "%.2f", high24h))")
        } else {
            high24hView.setValue("N/A")
        }
        
        if let low24h = coin.low24h {
            low24hView.setValue("$\(String(format: "%.2f", low24h))")
        } else {
            low24hView.setValue("N/A")
        }
        
        if let circulatingSupply = coin.circulatingSupply {
            circulatingSupplyView.setValue(circulatingSupply.formatted(style: .supply))
        } else {
            circulatingSupplyView.setValue("N/A")
        }
        
        if let totalSupply = coin.totalSupply {
            totalSupplyView.setValue(totalSupply.formatted(style: .supply))
        } else {
            totalSupplyView.setValue("N/A")
        }
        
        if let maxSupply = coin.maxSupply {
            maxSupplyView.setValue(maxSupply.formatted(style: .supply))
        } else {
            maxSupplyView.setValue("N/A")
        }
    }

    func updateFavoriteButton(_ isFavorite: Bool) {
        let imageName = isFavorite ? "star.fill" : "star"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        favoriteButton.setImage(UIImage(systemName: imageName), for: .highlighted)
    }

    func updateChart(with priceHistory: [CoinPrice]) {
        chartView.updateChart(with: priceHistory)
    }

    func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            chartLoadingIndicator.startAnimating()
        } else {
            chartLoadingIndicator.stopAnimating()
        }
    }

    func updateTimeRangeSelection(_ timeRange: TimeRangeType) {
        switch timeRange {
        case .day: timeRangeSegmentedControl.selectedSegmentIndex = 0
        case .week: timeRangeSegmentedControl.selectedSegmentIndex = 1
        case .month: timeRangeSegmentedControl.selectedSegmentIndex = 2
        }
    }
}
