import Foundation
import Combine

protocol FavoritesStore {
    var favoriteIDs: AnyPublisher<[String], Never> { get }

    func add(_ coin: CoinModel)
    func remove(_ coin: CoinModel)
    func isFavorite(_ coin: CoinModel) -> Bool
    func allFavorites() -> [String]
}

final class FavoritesStoreImpl: FavoritesStore {
    private let key: String
    private let userDefaults: UserDefaults
    private let favoriteIDsSubject: CurrentValueSubject<[String], Never>

    init(key: String, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.userDefaults = userDefaults

        let stored = userDefaults.stringArray(forKey: key) ?? []
        self.favoriteIDsSubject = CurrentValueSubject(stored)

        print("[FavoritesStore] Initialized with \(stored.count) items")
    }

    var favoriteIDs: AnyPublisher<[String], Never> {
        favoriteIDsSubject
            .handleEvents(receiveOutput: { ids in
                print("[FavoritesStore] Emitting favoriteIDs: \(ids)")
            })
            .eraseToAnyPublisher()
    }

    func add(_ coin: CoinModel) {
        var current = favoriteIDsSubject.value
        guard !current.contains(coin.id) else {
            print("[FavoritesStore] Attempted to add \(coin.id), but it's already a favorite")
            return
        }

        current.append(coin.id)
        print("[FavoritesStore] Added \(coin.id) to favorites")
        save(current)
    }

    func remove(_ coin: CoinModel) {
        let updated = favoriteIDsSubject.value.filter { $0 != coin.id }
        if updated.count == favoriteIDsSubject.value.count {
            print("[FavoritesStore] Attempted to remove \(coin.id), but it wasn't in favorites")
        } else {
            print("[FavoritesStore] Removed \(coin.id) from favorites")
        }
        save(updated)
    }

    func isFavorite(_ coin: CoinModel) -> Bool {
        let result = favoriteIDsSubject.value.contains(coin.id)
        print("[FavoritesStore] isFavorite(\(coin.id)) -> \(result)")
        return result
    }

    func allFavorites() -> [String] {
        let current = favoriteIDsSubject.value
        print("[FavoritesStore] allFavorites() -> \(current.count) items")
        return current
    }

    private func save(_ ids: [String]) {
        favoriteIDsSubject.send(ids)
        userDefaults.set(ids, forKey: key)
        print("[FavoritesStore] Saved \(ids.count) favorites to UserDefaults")
    }
}
