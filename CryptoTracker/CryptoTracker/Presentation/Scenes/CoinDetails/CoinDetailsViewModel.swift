import Combine
import UIKit

final class CoinDetailsViewModel: CombinableViewModel {
    private let router: CoinDetailsRouter
    private let coin: CoinModel
    private let favoritesStore: FavoritesStore
    private let coinsRepository: CoinsRepository

    init
    (
        router: CoinDetailsRouter,
        coin: CoinModel,
        favoritesStore: FavoritesStore,
        coinsRepository: CoinsRepository
    ) {
        self.router = router
        self.coin = coin
        self.favoritesStore = favoritesStore
        self.coinsRepository = coinsRepository
    }
}

//MARK: - CombinableViewModel
extension CoinDetailsViewModel {
    struct Input {
        let didLoad: AnyPublisher<Void, Never>
        let favoriteTrigger: AnyPublisher<Void, Never>
        let timeRangeTrigger: PassthroughSubject<TimeRangeType, Never>
    }

    final class Output: ObservableObject {
        @Published fileprivate(set) var coin: CoinModel = .empty
        @Published fileprivate(set) var isFavorite: Bool = false
        @Published fileprivate(set) var priceHistory: [CoinPrice] = []
        @Published fileprivate(set) var isLoadingPriceHistory = false
        @Published fileprivate(set) var currentTimeRange: TimeRangeType = .day
    }

    func transform(input: Input, cancelBag: CancelBag) -> Output {
        let output = Output()

        favoritesStore.favoriteCoins
            .map { [weak self] favoriteCoins in
                guard let self else {
                    return false
                }

                return favoriteCoins.contains(where: { $0.id == self.coin.id })
            }
            .assign(to: \.isFavorite, on: output)
            .store(in: cancelBag)

        input.didLoad
            .map { TimeRangeType.day }
            .map { timeRangeType in
                input.timeRangeTrigger.send(timeRangeType)
                return timeRangeType
            }
            .assign(to: \.currentTimeRange, on: output)
            .store(in: cancelBag)

        input.didLoad
            .sink { [weak self] in
                guard let self else {
                    return
                }

                output.coin = self.coin
            }
            .store(in: cancelBag)

        input.timeRangeTrigger
            .flatMap { [weak self] timeRange in
                guard let self else {
                    return Empty<[CoinPrice], Never>().eraseToAnyPublisher()
                }
                output.isLoadingPriceHistory = true
                debugPrint("🔄 Loading price history for \(self.coin.id) with timeRange: \(timeRange.rawValue)")
                return self.coinsRepository.fetchCoinPriceHistory(coinId: self.coin.id, timeRange: timeRange)
                    .retryWhen { [weak self] result, _ in
                        guard let self else {
                            return Just(false).eraseToAnyPublisher()
                        }

                        switch result {
                        case .success:
                            return Just(false).eraseToAnyPublisher()
                        case .failure:
                            output.isLoadingPriceHistory = false
                            return self.router.showAlertOfType(.fetchCoinsMarketsError)
                                .map { actionType in
                                    if case .bool(let shouldRetry) = actionType, shouldRetry {
                                        output.isLoadingPriceHistory = true
                                        return true
                                    }
                                    return false
                                }
                                .eraseToAnyPublisher()
                        }
                    }
                    .catch { _ in
                        output.isLoadingPriceHistory = false
                        return Empty<[CoinPrice], Never>().eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { _ in
                output.isLoadingPriceHistory = false
            })
            .assign(to: \.priceHistory, on: output)
            .store(in: cancelBag)

        input.favoriteTrigger
            .withLatestFrom(output.$isFavorite)
            .sink { [weak self] _, isFavorite in
                guard let self else {
                    return
                }

                if isFavorite {
                    self.favoritesStore.remove(self.coin)
                } else {
                    self.favoritesStore.add(self.coin)
                }
            }
            .store(in: cancelBag)

        return output
    }
}
