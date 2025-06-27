import Combine
import UIKit

final class RootViewModel: CombinableViewModel {
    private let router: RootRouter

    init
    (
        router: RootRouter
    ) {
        self.router = router
    }
}

//MARK: - CombinableViewModel
extension RootViewModel {
    struct Input {
        let didLoad: AnyPublisher<Void, Never>
    }

    final class Output: ObservableObject {}

    func transform(input: Input, cancelBag: CancelBag) -> Output {
        let output = Output()

        /// Добавил Root экран так как в дальнейшем может быть добавлен  Onboarding flow либо что-то другое
        /// так же в didLoad можно будет сделать какой-нибудь запрос до показа экранов либо добавить анимацию загрузки и тд
        input.didLoad
            .sink { [weak self] in
                guard let self else {
                    return
                }

                self.router.showMainScene()
            }
            .store(in: cancelBag)

        return output
    }
}
