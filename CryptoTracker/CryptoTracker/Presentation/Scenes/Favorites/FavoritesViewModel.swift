import Combine
import UIKit

final class FavoritesViewModel: CombinableViewModel {
    private let router: FavoritesRouter
    private let coinsRepository: CoinsRepository
    private let favoritesStore: FavoritesStore

    init
    (
        router: FavoritesRouter,
        coinsRepository: CoinsRepository,
        favoritesStore: FavoritesStore
    ) {
        self.router = router
        self.coinsRepository = coinsRepository
        self.favoritesStore = favoritesStore
    }
}

//MARK: - CombinableViewModel
extension FavoritesViewModel {
    struct Input {
        let didLoad: AnyPublisher<Void, Never>
        let refreshTrigger: AnyPublisher<Void, Never>
        let didReachBottom: AnyPublisher<Void, Never>
        let favoriteAtIndexPathTrigger: AnyPublisher<IndexPath, Never>
    }

    final class Output: ObservableObject {
        @Published fileprivate(set) var isLoading = false
        @Published fileprivate(set) var coinModels: [CoinModel] = []
    }

    func transform(input: Input, cancelBag: CancelBag) -> Output {
        let output = Output()

        input.didLoad
            .sink { [weak self] in
                guard let self else {
                    return
                }

            }
            .store(in: cancelBag)

        return output
    }
}
