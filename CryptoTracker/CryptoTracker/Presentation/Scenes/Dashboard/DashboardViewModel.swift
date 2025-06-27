import Foundation
import Combine

final class DashboardViewModel: CombinableViewModel {
    private let router: DashboardRouter

    init
    (
        router: DashboardRouter
    ) {
        self.router = router
    }
}

//MARK: - CombinableViewModel
extension DashboardViewModel {
    struct Input {
        let willAppear: AnyPublisher<Void, Never>
    }

    final class Output: ObservableObject {}

    func transform(input: Input, cancelBag: CancelBag) -> Output {
        let output = Output()

        input.willAppear
            .sink { [weak self] in
                guard let self else {
                    return
                }

                self.router.showTabs()
            }
            .store(in: cancelBag)

        return output
    }
}
