import Combine

final class CancelBag {
    var subscriptions = Set<AnyCancellable>()

    func cancel() {
        subscriptions.forEach { $0.cancel() }
        subscriptions.removeAll()
    }
}
