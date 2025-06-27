import UIKit

protocol DashboardRouter {
    func showTabs()
}

final class DashboardRouterImpl: DashboardRouter {
    private weak var view: UITabBarController?
    private let homeBuilder: HomeBuilder
    private let favoritesBuilder: FavoritesBuilder

    init
    (
        view: UITabBarController,
        homeBuilder: HomeBuilder,
        favoritesBuilder: FavoritesBuilder
    ) {
        self.view = view
        self.homeBuilder = homeBuilder
        self.favoritesBuilder = favoritesBuilder
    }

    func showTabs() {
        let homeVC = homeBuilder
            .build()
        let homeNavigationVC = UINavigationController(rootViewController: homeVC)
        homeNavigationVC.setNavigationBarHidden(true, animated: false)
        homeNavigationVC.tabBarItem.title = "Home"
        homeNavigationVC.tabBarItem.image = UIImage(systemName: "house")

        let favoritesVC = favoritesBuilder
            .build()
        let favoritesNavigationVC = UINavigationController(rootViewController: favoritesVC)
        favoritesNavigationVC.setNavigationBarHidden(true, animated: false)
        favoritesNavigationVC.tabBarItem.title = "Favorites"
        favoritesNavigationVC.tabBarItem.image = UIImage(systemName: "star")

        view?.viewControllers = [
            homeNavigationVC,
            favoritesNavigationVC
        ]
    }
}
