import Foundation
import Combine

protocol FavoritesStore {
    var favoriteIDs: AnyPublisher<[String], Never> { get }

    func refresh()
    func add(_ coin: CoinModel)
    func remove(_ coin: CoinModel)
    func isFavorite(_ coin: CoinModel) -> Bool
    func allFavorites() -> [String]
}

final class FavoritesStoreImpl: FavoritesStore {
    private let key: String
    private let userDefaults: UserDefaults

    init
    (
        key: String,
        userDefaults: UserDefaults = .standard
    ) {
        self.key = key
        self.userDefaults = userDefaults
    }

    private let favoriteIDsSubject = CurrentValueSubject<[String], Never>([])
    private(set) lazy var favoriteIDs: AnyPublisher<[String], Never> = {
        favoriteIDsSubject.eraseToAnyPublisher()
    }()

    func refresh() {
        let favoriteIDs = allFavorites()
        favoriteIDsSubject.send(favoriteIDs)
    }

    func add(_ coin: CoinModel) {
        var favorites = allFavorites()
        guard
            !favorites.contains(coin.id) else {
            return
        }

        favorites.append(coin.id)
        save(favorites)
    }

    func remove(_ coin: CoinModel) {
        let currentFavorites = allFavorites()
        let updated = currentFavorites.filter { $0 != coin.id }

        save(updated)
    }

    func isFavorite(_ coin: CoinModel) -> Bool {
        return allFavorites().contains(coin.id)
    }

    func allFavorites() -> [String] {
        let value = userDefaults.stringArray(forKey: key) ?? []
        return value
    }
}

private extension FavoritesStoreImpl {
    func save(_ ids: [String]) {
        userDefaults.set(ids, forKey: key)
        refresh()
    }
}
