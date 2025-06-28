import Combine
import UIKit

final class HomeViewModel: CombinableViewModel {
    private var currentPage = 1
    private let perPage = 25
    private var isLoadingPage = false
    private var hasMorePages = true

    @Published private var sortOption: SortOption? = nil
    @Published private var filterOption: FilterOption? = nil

    private let router: HomeRouter
    private let coinsRepository: CoinsRepository

    init(
        router: HomeRouter,
        coinsRepository: CoinsRepository
    ) {
        self.router = router
        self.coinsRepository = coinsRepository
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
    }

    final class Output: ObservableObject {
        @Published fileprivate(set) var isLoading = false
        @Published fileprivate(set) var rawCoinModels: [CoinModel] = []
        @Published fileprivate(set) var coinModels: [CoinModel] = []
    }

    func transform(input: Input, cancelBag: CancelBag) -> Output {
        let output = Output()

        // Load & Pagination
        input.didLoad
            .merge(with: input.refreshTrigger)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.currentPage = 1
                self?.hasMorePages = true
            })
            .merge(with: input.didReachBottom
                .filter { [weak self] in
                    guard let self = self else { return false }
                    return !self.isLoadingPage && self.hasMorePages
                }
            )
            .flatMap { [weak self] in
                guard let self = self else {
                    return Empty<[CoinModel], Never>().eraseToAnyPublisher()
                }

                self.isLoadingPage = true
                output.isLoading = true

                return self.coinsRepository.fetchCoinsMarkets(page: self.currentPage, perPage: self.perPage)
                    .retryWhen { [weak self] result, _ in
                        guard let self = self else { return Just(false).eraseToAnyPublisher() }
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
                        guard let self = self else { return [] }

                        var _newCoins = newCoins
                        if _newCoins.isEmpty {
                            _newCoins = self.coinsRepository.getCachedCoins()
                        }

                        if _newCoins.count < self.perPage {
                            self.hasMorePages = false
                        } else {
                            self.currentPage += 1
                        }

                        if self.currentPage == 2 {
                            return _newCoins
                        } else {
                            return output.rawCoinModels + _newCoins
                        }
                    }
                    .handleEvents(receiveOutput: { [weak self] _ in
                        output.isLoading = false
                        self?.isLoadingPage = false
                    })
                    .eraseToAnyPublisher()
            }
            .assign(to: \.rawCoinModels, on: output)
            .store(in: cancelBag)

        // Empty search
        input.searchTextDidChangeTrigger
            .filter { $0.isEmpty }
            .sink { [weak self] _ in
                guard let self = self else { return }

                let cached = self.coinsRepository.getCachedCoins()
                if cached.isEmpty {
                    input.refreshTrigger.send(())
                } else {
                    output.rawCoinModels = cached
                }
            }
            .store(in: cancelBag)

        // Full search
        input.searchTextDidChangeTrigger
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .flatMap { [weak self] query -> AnyPublisher<[CoinModel], Never> in
                guard let self = self else {
                    return Just<[CoinModel]>([])
                        .eraseToAnyPublisher()
                }

                return self.coinsRepository.search(query: query)
                    .catch { _ in Just<[CoinModel]>([]) }
                    .eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .sink { models in
                output.rawCoinModels = models
            }
            .store(in: cancelBag)

        // Sort
        input.sortTrigger
            .flatMap { [weak self] in
                guard let self = self else { return Empty<AlertActionType, Never>().eraseToAnyPublisher() }
                return self.router.showAlertOfType(.sort)
            }
            .compactMap {
                if case let .sort(option) = $0 { return option }
                return nil
            }
            .sink { [weak self] option in
                self?.sortOption = option
            }
            .store(in: cancelBag)

        // Filter
        input.filterTrigger
            .flatMap { [weak self] in
                guard let self = self else { return Empty<AlertActionType, Never>().eraseToAnyPublisher() }
                return self.router.showAlertOfType(.filter)
            }
            .compactMap {
                if case let .filter(option) = $0 { return option }
                return nil
            }
            .sink { [weak self] option in
                self?.filterOption = option
            }
            .store(in: cancelBag)

        // Sort/Filter
        Publishers.CombineLatest3(
            output.$rawCoinModels,
            $sortOption,
            $filterOption
        )
        .map { coinModels, sortOption, filterOption in
            var models = coinModels

            if let filterOption = filterOption {
                switch filterOption {
                case .top10:
                    models = Array(models.prefix(10))
                case .priceAbove1:
                    models = models.filter { $0.price > 1 }
                }
            }

            if let sortOption = sortOption {
                switch sortOption {
                case .priceAscending:
                    models.sort { $0.price < $1.price }
                case .priceDescending:
                    models.sort { $0.price > $1.price }
                case .nameAZ:
                    models.sort { $0.name.lowercased() < $1.name.lowercased() }
                case .nameZA:
                    models.sort { $0.name.lowercased() > $1.name.lowercased() }
                }
            }

            return models
        }
        .receive(on: RunLoop.main)
        .assign(to: \.coinModels, on: output)
        .store(in: cancelBag)

        return output
    }
}
