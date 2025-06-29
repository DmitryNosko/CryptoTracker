import UIKit
import Combine

protocol CoinDetailsRouter {}

final class CoinDetailsRouterImpl: CoinDetailsRouter {
    private weak var view: UIViewController?

    init
    (
        view: UIViewController
    ) {
        self.view = view
    }
}
