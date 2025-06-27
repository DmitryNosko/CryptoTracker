import UIKit
import Combine

protocol FavoritesRouter {
}

final class FavoritesRouterImpl: FavoritesRouter {
    private weak var view: UIViewController?

    init
    (
        view: UIViewController
    ) {
        self.view = view
    }
}
