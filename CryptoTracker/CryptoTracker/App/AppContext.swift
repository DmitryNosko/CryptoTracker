import Foundation

final class AppContext {
    private var factories: [String: () -> Any] = [:]

    init() {
        registerDependencies()
    }

    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }

    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        guard
            let factory = factories[key],
            let instance = factory() as? T
        else {
            fatalError("🛑 No registered factory for \(key)")
        }
        return instance
    }

    func registerLazy<T>(_ type: T.Type, factory: @escaping @autoclosure () -> T) {
        var cachedInstance: T?
        register(type) {
            if let instance = cachedInstance {
                return instance
            } else {
                let instance = factory()
                cachedInstance = instance
                return instance
            }
        }
    }
}

private extension AppContext {
    func registerDependencies() {
        registerLazy(
            CoinsAPIService.self,
            factory: CoinsAPIServiceImpl()
        )
        registerLazy(
            CoinCache.self,
            factory: CoinCacheImpl(
                filename: AppConstants.Cache.cashJsonName,
                ttl: AppConstants.Cache.ttl
            )
        )
        registerLazy(
            FavoritesStore.self,
            factory: FavoritesStoreImpl(key: AppConstants.FavoriteCoins.key)
        )
        registerLazy(
            CoinsRepository.self,
            factory: CoinsRepositoryImpl(
                coinsAPIService: self.resolve(CoinsAPIService.self),
                coinCache: self.resolve(CoinCache.self)
            )
        )
        registerLazy(
            CoinFilteringService.self,
            factory: CoinFilteringServiceImpl()
        )
        registerLazy(
            CoinSortingService.self,
            factory: CoinSortingServiceImpl()
        )
        registerLazy(
            NotificationService.self,
            factory: NotificationServiceImpl()
        )
        registerLazy(
            PriceAlertService.self,
            factory: PriceAlertServiceImpl(
                notificationService: self.resolve(NotificationService.self),
                significantChangeThreshold: AppConstants.Notification.significantChangeThreshold
            )
        )
    }
}
