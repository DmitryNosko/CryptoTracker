import Combine
import UIKit

final class FavoritesViewModel: CombinableViewModel {
    private let router: FavoritesRouter
    private let favoritesStore: FavoritesStore

    init
    (
        router: FavoritesRouter,
        favoritesStore: FavoritesStore
    ) {
        self.router = router
        self.favoritesStore = favoritesStore
    }
}

// MARK: - CombinableViewModel
extension FavoritesViewModel {
    struct Input {
        let favoriteAtIndexPathTrigger: AnyPublisher<IndexPath, Never>
    }

    final class Output: ObservableObject {
        @Published fileprivate(set) var coinModels: [CoinModel] = []
    }

    func transform(input: Input, cancelBag: CancelBag) -> Output {
        let output = Output()

        favoritesStore.favoriteCoins
            .sink { favoriteCoins in
                output.coinModels = favoriteCoins
            }
            .store(in: cancelBag)

        input.favoriteAtIndexPathTrigger
            .withLatestFrom(output.$coinModels)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] indexPath, coinModels in
                guard let self else {
                    return
                }

                guard !coinModels.isEmpty else {
                    return
                }

                guard
                    indexPath.section >= 0 && indexPath.section < coinModels.count
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

        return output
    }
}
