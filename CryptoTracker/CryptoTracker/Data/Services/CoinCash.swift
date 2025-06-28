import Foundation

protocol CoinCache {
    func save(_ coins: [CoinModel])
    func load() -> [CoinModel]
    func clear()
}

final class CoinCacheImpl: CoinCache {
    private let fileURL: URL
    private let ttl: TimeInterval

    init
    (
        filename: String,
        ttl: TimeInterval
    ) {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = directory.appendingPathComponent(filename)
        self.ttl = ttl
    }

    func save(_ coins: [CoinModel]) {
        let existing = load()
        let merged = mergeCoins(old: existing, new: coins)
        let wrapper = CoinCacheWrapper(timestamp: Date(), coins: merged)

        do {
            let data = try JSONEncoder().encode(wrapper)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            debugPrint("🛑 Failed to save coins to cache: \(error)")
        }
    }

    func load() -> [CoinModel] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let wrapper = try JSONDecoder().decode(CoinCacheWrapper.self, from: data)

            let age = Date().timeIntervalSince(wrapper.timestamp)
            if age > ttl {
                debugPrint("⚠️ Cache expired (\(Int(age))s > \(Int(ttl))s), clearing")
                clear()
                return []
            }

            return wrapper.coins
        } catch {
            debugPrint("🛑 Failed to load coins from cache: \(error)")
            return []
        }
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

private extension CoinCacheImpl {
    func mergeCoins(old: [CoinModel], new: [CoinModel]) -> [CoinModel] {
        var dict = Dictionary(uniqueKeysWithValues: old.map { ($0.id, $0) })
        for coin in new {
            dict[coin.id] = coin
        }
        return Array(dict.values)
    }
}
