import Combine
import UIKit

final class CoinDetailsViewModel: CombinableViewModel {
    private let router: CoinDetailsRouter
    private let coin: CoinModel

    init
    (
        router: CoinDetailsRouter,
        coin: CoinModel
    ) {
        self.router = router
        self.coin = coin
    }
}

//MARK: - CombinableViewModel
extension CoinDetailsViewModel {
    struct Input {
        let didLoad: AnyPublisher<Void, Never>
    }

    final class Output: ObservableObject {}

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
