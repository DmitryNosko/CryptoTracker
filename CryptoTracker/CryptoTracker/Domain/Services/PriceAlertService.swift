import Foundation
import Combine

protocol PriceAlertService {
    @discardableResult
    func checkSignificantPriceChanges(coins: [CoinModel]) -> AnyPublisher<Void, Never>
}

final class PriceAlertServiceImpl: PriceAlertService {
    private let notificationService: NotificationService
    private let significantChangeThreshold: Double

    init
    (
        notificationService: NotificationService,
        significantChangeThreshold: Double
    ) {
        self.notificationService = notificationService
        self.significantChangeThreshold = significantChangeThreshold
    }
    
    func checkSignificantPriceChanges(coins: [CoinModel]) -> AnyPublisher<Void, Never> {
        return Just(())
            .map { [weak self] in
                guard let self = self else { return }
                // на данном этапе чтобы просто показать работу беру первый из массива, в конечном итоге можно улучшать и делать кастомное поведение какое только пожелаем
                if let firstCoin = coins.first {
                    let priceChange = firstCoin.priceChangePercentage24h ?? 0
                    if abs(priceChange) >= self.significantChangeThreshold {
                        self.notificationService.sendPriceChangeNotification(
                            coinName: firstCoin.name,
                            coinSymbol: firstCoin.symbol,
                            priceChange: priceChange,
                            currentPrice: firstCoin.price
                        )
                    }
                }
            }
            .eraseToAnyPublisher()
    }
}
