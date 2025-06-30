import Foundation
import UserNotifications
import Combine

protocol NotificationService {
    @discardableResult
    func requestPermission() -> AnyPublisher<Bool, Never>
    func sendPriceChangeNotification(coinName: String, coinSymbol: String, priceChange: Double, currentPrice: Double)
}

final class NotificationServiceImpl: NotificationService {
    private let notificationCenter = UNUserNotificationCenter.current()

    init() {
        setupNotificationCategories()
    }

    func requestPermission() -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                promise(.success(granted))
            }
        }
        .eraseToAnyPublisher()
    }

    func sendPriceChangeNotification
    (
        coinName: String,
        coinSymbol: String,
        priceChange: Double,
        currentPrice: Double
    ) {
        let content = UNMutableNotificationContent()
        content.title = "🤞🏾 \(coinSymbol) - Price Changed!"

        let changeDirection = priceChange >= 0 ? "📈" : "📉"
        let absChange = abs(priceChange)
        content.body = "\(changeDirection) \(coinName) changed on \(String(format: "%.2f", absChange))% - $\(String(format: "%.2f", currentPrice))"

        content.sound = .default
        content.categoryIdentifier = "PRICE_ALERT"

        let request = UNNotificationRequest(
            identifier: "\(coinSymbol)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { _ in }
    }

    private func setupNotificationCategories() {
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "OK",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "PRICE_ALERT",
            actions: [dismissAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([category])
    }
}
