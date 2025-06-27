import Combine
import UIKit

final class FavoritesViewModel: CombinableViewModel {
    private let router: FavoritesRouter

    init
    (
        router: FavoritesRouter
    ) {
        self.router = router
    }
}

//MARK: - CombinableViewModel
extension FavoritesViewModel {
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
