import Foundation
import Combine

protocol FavoritesStore {
    var favoriteCoins: AnyPublisher<[CoinModel], Never> { get }

    func add(_ coin: CoinModel)
    func remove(_ coin: CoinModel)
    func isFavorite(_ coin: CoinModel) -> Bool
}

final class FavoritesStoreImpl: FavoritesStore {
    private let key: String
    private let userDefaults: UserDefaults
    private let favoriteCoinsSubject: CurrentValueSubject<[CoinModel], Never>

    init
    (
        key: String,
        userDefaults: UserDefaults = .standard
    ) {
        self.key = key
        self.userDefaults = userDefaults

        let stored = userDefaults.data(forKey: key) ?? Data()
        let coins = (try? JSONDecoder().decode([CoinModel].self, from: stored)) ?? []
        self.favoriteCoinsSubject = CurrentValueSubject(coins)
    }

    var favoriteCoins: AnyPublisher<[CoinModel], Never> {
        favoriteCoinsSubject.eraseToAnyPublisher()
    }

    func add(_ coin: CoinModel) {
        var current = favoriteCoinsSubject.value
        guard !current.contains(where: { $0.id == coin.id }) else {
            return
        }

        var updatedCoin = coin
        updatedCoin.isFavorite = true
        current.append(updatedCoin)
        save(current)
    }

    func remove(_ coin: CoinModel) {
        let updated = favoriteCoinsSubject.value.filter { $0.id != coin.id }
        save(updated)
    }

    func isFavorite(_ coin: CoinModel) -> Bool {
        return favoriteCoinsSubject.value.contains(where: { $0.id == coin.id })
    }
}

private extension FavoritesStoreImpl {
    func save(_ coins: [CoinModel]) {
        favoriteCoinsSubject.send(coins)

        if let data = try? JSONEncoder().encode(coins) {
            userDefaults.set(data, forKey: key)
        }
    }
}
