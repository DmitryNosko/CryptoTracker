import UIKit
import Combine

protocol HomeRouter {
}

final class HomeRouterImpl: HomeRouter {
    private weak var view: UIViewController?

    init
    (
        view: UIViewController
    ) {
        self.view = view
    }
}
