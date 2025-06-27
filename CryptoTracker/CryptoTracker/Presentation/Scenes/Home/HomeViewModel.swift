import Combine
import UIKit

final class HomeViewModel: CombinableViewModel {
    private let router: HomeRouter

    init
    (
        router: HomeRouter
    ) {
        self.router = router
    }
}

//MARK: - CombinableViewModel
extension HomeViewModel {
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
