import Combine
import UIKit

final class HomeViewModel: CombinableViewModel {
    private var coinModels: [CoinModel] = []

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
    }

    final class Output: ObservableObject {
        @Published fileprivate(set) var isLoading = false
        @Published fileprivate(set) var coinModels: [CoinModel] = []
    }

    func transform(input: Input, cancelBag: CancelBag) -> Output {
        let output = Output()

        input.didLoad
            .flatMap { [weak self] in
                guard let self else {
                    return Empty<[CoinModel], Never>()
                        .eraseToAnyPublisher()
                }

                output.isLoading = true
                return self.coinsRepository.fetchCoinsMarkets(page: 1, perPage: 25)
                    .receive(on: DispatchQueue.main)
                    .retryWhen { result, attempt  in
                        switch result {
                        case .success(_):
                            return Just(false).eraseToAnyPublisher()
                        case .failure(_):
                            output.isLoading = false
                            return self.router.showAlertOfType(.fetchCoinsMarketsError)
                                .map { alertActionType in
                                    if case .bool(let shouldRetryRequest) = alertActionType {
                                        if shouldRetryRequest {
                                            output.isLoading = true
                                        }
                                        return shouldRetryRequest
                                    }
                                    return false
                                }
                                .eraseToAnyPublisher()
                        }
                    }
                    .catch { error -> AnyPublisher<[CoinModel], Never> in
                        output.isLoading = false
                        return Empty<[CoinModel], Never>()
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .map { coinModels in
                output.isLoading = false
                return coinModels
            }
            .assign(to: \.coinModels, on: output)
            .store(in: cancelBag)

        return output
    }
}
