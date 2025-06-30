import Combine
import UIKit

final class HomeViewModel: CombinableViewModel {
    private var currentPage = 1
    private let perPage = 25
    private var isLoadingPage = false
    private var hasMorePages = true
    private var allCoins: [CoinModel] = [] {
        didSet {
            updateFilteredAndSortedCoins()
        }
    }
    private var currentFavoriteIDs: [String] = []
    private var currentSortOption: SortOptionType? = nil
    private var currentFilterOption: FilterOptionType? = nil
    @Published private var filteredAndSortedCoins: [CoinModel] = []

    private let router: HomeRouter
    private let coinsRepository: CoinsRepository
    private let favoritesStore: FavoritesStore
    private let coinFilteringService: CoinFilteringService
    private let coinSortingService: CoinSortingService
    private let priceAlertService: PriceAlertService
    private let notificationService: NotificationService

    init(
        router: HomeRouter,
        coinsRepository: CoinsRepository,
        favoritesStore: FavoritesStore,
        coinFilteringService: CoinFilteringService,
        coinSortingService: CoinSortingService,
        priceAlertService: PriceAlertService,
        notificationService: NotificationService
    ) {
        self.router = router
        self.coinsRepository = coinsRepository
        self.favoritesStore = favoritesStore
        self.coinFilteringService = coinFilteringService
        self.coinSortingService = coinSortingService
        self.priceAlertService = priceAlertService
        self.notificationService = notificationService
    }
}

// MARK: - CombinableViewModel
extension HomeViewModel {
    struct Input {
        let didLoad: AnyPublisher<Void, Never>
        let refreshTrigger: PassthroughSubject<Void, Never>
        let didReachBottom: AnyPublisher<Void, Never>
        let searchTextDidChangeTrigger: AnyPublisher<String, Never>
        let sortTrigger: AnyPublisher<Void, Never>
        let filterTrigger: AnyPublisher<Void, Never>
        let favoriteAtIndexPathTrigger: AnyPublisher<IndexPath, Never>
        let didSelectCoinAtIndexPath: AnyPublisher<IndexPath, Never>
    }

    final class Output: ObservableObject {
        @Published fileprivate(set) var isLoading = false
        @Published fileprivate(set) var coinModels: [CoinModel] = []
    }

    func transform(input: Input, cancelBag: CancelBag) -> Output {
        let output = Output()

        $filteredAndSortedCoins
            .assign(to: \ .coinModels, on: output)
            .store(in: cancelBag)

        favoritesStore.favoriteCoins
            .sink { [weak self] favoriteCoins in
                guard let self else { return }
                self.currentFavoriteIDs = favoriteCoins.map(\.id)
                self.allCoins = self.allCoins.map { coin in
                    var updated = coin
                    updated.isFavorite = favoriteCoins.contains(where: { $0.id == coin.id })
                    return updated
                }
            }
            .store(in: cancelBag)

        input.didLoad
            .flatMap { [weak self] in
                guard let self else {
                    return Just(false).eraseToAnyPublisher()
                }

                return self.notificationService.requestPermission()
            }
            .debounce(for: .seconds(AppConstants.Notification.checkSignificantPriceChangesDebounce), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }

                self.priceAlertService.checkSignificantPriceChanges(coins: self.allCoins)
            }
            .store(in: cancelBag)

        input.didLoad
            .merge(with: input.refreshTrigger)
            .merge(with: input.didReachBottom
                .filter { [weak self] in
                    guard let self else { return false }
                    return !self.isLoadingPage && self.hasMorePages
                })
            .flatMap { [weak self] in
                guard let self else {
                    return Empty<[CoinModel], Never>().eraseToAnyPublisher()
                }

                self.isLoadingPage = true
                output.isLoading = true

                return self.coinsRepository.fetchCoinsMarkets(page: self.currentPage, perPage: self.perPage, ids: nil)
                    .retryWhen { [weak self] result, _ in
                        guard let self else {
                            return Just(false).eraseToAnyPublisher()
                        }

                        switch result {
                        case .success:
                            return Just(false).eraseToAnyPublisher()
                        case .failure:
                            output.isLoading = false
                            return self.router.showAlertOfType(.fetchCoinsMarketsError)
                                .map { actionType in
                                    if case .bool(let shouldRetry) = actionType, shouldRetry {
                                        output.isLoading = true
                                        return true
                                    }
                                    return false
                                }
                                .eraseToAnyPublisher()
                        }
                    }
                    .catch { _ in
                        output.isLoading = false
                        return Empty<[CoinModel], Never>().eraseToAnyPublisher()
                    }
                    .map { [weak self] newCoins in
                        guard let self else { return [] }

                        var coins = newCoins
                        if coins.isEmpty {
                            coins = self.coinsRepository.getCachedCoins()
                        }

                        if coins.count < self.perPage {
                            self.hasMorePages = false
                        } else {
                            self.currentPage += 1
                        }

                        let newUniqueCoins = coins.filter { newCoin in
                            !self.allCoins.contains(where: { $0.id == newCoin.id })
                        }
                        return newUniqueCoins
                    }
                    .handleEvents(receiveOutput: { [weak self] newCoins in
                        guard let self else { return }
                        self.isLoadingPage = false
                        output.isLoading = false
                        let updatedCoins = self.updateFavorites(in: newCoins)
                        self.allCoins.append(contentsOf: updatedCoins)
                    })
                    .eraseToAnyPublisher()
            }
            .sink { _ in }
            .store(in: cancelBag)

        input.searchTextDidChangeTrigger
            .filter { $0.isEmpty }
            .sink { [weak self] _ in
                guard let self else {
                    return
                }

                let cachedCoins = self.coinsRepository.getCachedCoins()
                if cachedCoins.isEmpty {
                    input.refreshTrigger.send(())
                }

                let updatedCoins = self.updateFavorites(in: cachedCoins)
                self.allCoins = updatedCoins
            }
            .store(in: cancelBag)


        input.searchTextDidChangeTrigger
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .flatMap { [weak self] query -> AnyPublisher<[CoinModel], Never> in
                guard let self else { return Just([]).eraseToAnyPublisher() }
                return self.coinsRepository.search(query: query)
                    .catch { _ in Just([]) }
                    .eraseToAnyPublisher()
            }
            .sink { [weak self] results in
                guard let self else {
                    return
                }

                let updatedResults = self.updateFavorites(in: results)
                self.allCoins = updatedResults
            }
            .store(in: cancelBag)

        input.sortTrigger
            .flatMap { [weak self] in
                guard let self else {
                    return Empty<AlertActionType, Never>().eraseToAnyPublisher()
                }
                return self.router.showAlertOfType(.sort)
            }
            .compactMap {
                if case let .sort(option) = $0 {
                    return option
                }
                return nil
            }
            .sink { [weak self] option in
                guard let self else { return }
                self.currentSortOption = option
                self.updateFilteredAndSortedCoins()
            }
            .store(in: cancelBag)

        input.filterTrigger
            .flatMap { [weak self] in
                guard let self else {
                    return Empty<AlertActionType, Never>().eraseToAnyPublisher()
                }
                return self.router.showAlertOfType(.filter)
            }
            .compactMap {
                if case let .filter(option) = $0 {
                    return option
                }
                return nil
            }
            .sink { [weak self] option in
                guard let self else { return }
                self.currentFilterOption = option
                self.updateFilteredAndSortedCoins()
            }
            .store(in: cancelBag)

        input.favoriteAtIndexPathTrigger
            .withLatestFrom($filteredAndSortedCoins)
            .sink { [weak self] indexPath, coinModels in
                guard
                    let self,
                    coinModels.indices.contains(indexPath.section)
                else {
                    return
                }

                let coin = coinModels[indexPath.section]

                if self.favoritesStore.isFavorite(coin) {
                    self.favoritesStore.remove(coin)
                } else {
                    self.favoritesStore.add(coin)
                }
            }
            .store(in: cancelBag)

        input.didSelectCoinAtIndexPath
            .withLatestFrom(output.$coinModels)
            .sink { [weak self] indexPath, coinModels in
                guard let self else {
                    return
                }

                let selectedCoin = coinModels[indexPath.section]
                self.router.showCoinDetails(selectedCoin)
            }
            .store(in: cancelBag)

        return output
    }
}

// MARK: - Helpers
private extension HomeViewModel {
    func applySortAndFilter(_ models: [CoinModel]) -> [CoinModel] {
        var result = models

        if let filter = currentFilterOption {
            result = coinFilteringService.filter(result, by: filter)
        }

        if let sort = currentSortOption {
            result = coinSortingService.sort(result, by: sort)
        }

        return result
    }

    func updateFilteredAndSortedCoins() {
        self.filteredAndSortedCoins = applySortAndFilter(allCoins)
    }

    private func updateFavorites(in coins: [CoinModel]) -> [CoinModel] {
        return coins.map { coin in
            var updated = coin
            updated.isFavorite = currentFavoriteIDs.contains(coin.id)
            return updated
        }
    }
}
