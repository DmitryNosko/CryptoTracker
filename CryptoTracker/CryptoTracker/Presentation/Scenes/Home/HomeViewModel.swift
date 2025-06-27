import Combine
import UIKit

final class HomeViewModel: CombinableViewModel {
    // Data
    private var coinModels: [CoinModel] = []
    private var currentPage = 1
    private let perPage = 25
    private var isLoadingPage = false
    private var hasMorePages = true

    // Init
    private let router: HomeRouter
    private let coinsRepository: CoinsRepository

    init
    (
        router: HomeRouter,
        coinsRepository: CoinsRepository
    ) {
        self.router = router
        self.coinsRepository = coinsRepository
    }
}

//MARK: - CombinableViewModel
extension HomeViewModel {
    struct Input {
        let didLoad: AnyPublisher<Void, Never>
        let refreshTrigger: AnyPublisher<Void, Never>
        let didReachBottom: AnyPublisher<Void, Never>
    }

    final class Output: ObservableObject {
        @Published fileprivate(set) var isLoading = false
        @Published fileprivate(set) var coinModels: [CoinModel] = []
    }

    func transform(input: Input, cancelBag: CancelBag) -> Output {
        let output = Output()

        input.didLoad
            .merge(with: input.refreshTrigger)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.currentPage = 1
                self?.hasMorePages = true
            })
            .merge(with: input.didReachBottom
                .filter { [weak self] in
                    guard let self else {
                        return false
                    }

                    return !self.isLoadingPage && self.hasMorePages
                }
            )
            .flatMap { [weak self] in
                guard let self else {
                    return Empty<[CoinModel], Never>().eraseToAnyPublisher()
                }

                self.isLoadingPage = true
                output.isLoading = true

                return self.coinsRepository.fetchCoinsMarkets(page: self.currentPage, perPage: self.perPage)
                    .retryWhen { result, attempt in
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
                    .catch { _ -> AnyPublisher<[CoinModel], Never> in
                        output.isLoading = false
                        return Empty().eraseToAnyPublisher()
                    }
                    .map { [weak self] newCoins in
                        guard let self else {
                            return []
                        }

                        if newCoins.count < self.perPage {
                            self.hasMorePages = false
                        } else {
                            self.currentPage += 1
                        }

                        if self.currentPage == 2 {
                            return newCoins
                        } else {
                            return output.coinModels + newCoins
                        }
                    }
                    .handleEvents(receiveOutput: { _ in
                        output.isLoading = false
                        self.isLoadingPage = false
                    })
                    .eraseToAnyPublisher()
            }
            .assign(to: \.coinModels, on: output)
            .store(in: cancelBag)

        return output
    }
}
