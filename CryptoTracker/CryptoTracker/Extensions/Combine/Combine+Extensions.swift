import Foundation
import Combine

//MARK: - AnyCancellable
extension AnyCancellable {
    func store(in cancelBag: CancelBag) {
        cancelBag.subscriptions.insert(self)
    }
}

// MARK: - RetryWhen
extension Publisher {
    func retryWhen(
        max: Int = .max,
        delay: DispatchQueue.SchedulerTimeType.Stride = 0,
        _ predicate: @escaping (Result<Self.Output, Self.Failure>, Int) -> AnyPublisher<Bool, Never>
    ) -> Publishers.RetryWhen<Self> {
        .init(upstream: self, max: max, delay: delay, predicate: predicate)
    }
}

private class RetryWhenSubscriber<Downstream: Subscriber, Upstream: Publisher>: Subscription
where Downstream.Input == Upstream.Output, Downstream.Failure == Upstream.Failure {
    private var downstream: Downstream?
    private var upstreamSubscription: Subscription?
    private var retryCount = 0
    private let max: Int
    private let delay: DispatchQueue.SchedulerTimeType.Stride
    private let predicate: (Result<Upstream.Output, Upstream.Failure>, Int) -> AnyPublisher<Bool, Never>
    private let upstream: Upstream
    private var cancellable: AnyCancellable?

    init(
        upstream: Upstream,
        max: Int,
        delay: DispatchQueue.SchedulerTimeType.Stride,
        predicate: @escaping (Result<Upstream.Output, Upstream.Failure>, Int) -> AnyPublisher<Bool, Never>,
        downstream: Downstream
    ) {
        self.upstream = upstream
        self.max = max
        self.delay = delay
        self.predicate = predicate
        self.downstream = downstream
        startRequest()
    }

    private func startRequest() {
        let publisher = upstream.handleEvents(receiveCompletion: { [weak self] completion in
            guard let self = self else { return }
            switch completion {
            case .finished:
                break
            case .failure(let error):
                self.retryCount += 1
                if self.retryCount <= self.max {
                    self.handleFailure(result: .failure(error))
                } else {
                    self.downstream?.receive(completion: .failure(error))
                }
            }
        })

        publisher.subscribe(InnerSubscriber(parent: self))
    }

    private func handleFailure(result: Result<Downstream.Input, Downstream.Failure>) {
        let shouldRetryPublisher = predicate(result, retryCount)

        cancellable = shouldRetryPublisher.sink { [weak self] shouldRetry in
            guard let self = self else { return }
            if shouldRetry {
                self.startRequest()
            } else {
                if case let .failure(error) = result {
                    self.downstream?.receive(completion: .failure(error))
                }
            }
        }
    }

    func request(_ demand: Subscribers.Demand) {
        upstreamSubscription?.request(demand)
    }

    func cancel() {
        upstreamSubscription?.cancel()
        downstream = nil
        cancellable?.cancel()
    }

    private class InnerSubscriber: Subscriber {
        typealias Input = Downstream.Input
        typealias Failure = Downstream.Failure

        private let parent: RetryWhenSubscriber

        init(parent: RetryWhenSubscriber) {
            self.parent = parent
        }

        func receive(subscription: Subscription) {
            parent.upstreamSubscription = subscription
            subscription.request(.unlimited)
        }

        func receive(_ input: Downstream.Input) -> Subscribers.Demand {
            parent.downstream?.receive(input)
            return .unlimited
        }

        func receive(completion: Subscribers.Completion<Downstream.Failure>) {
            parent.downstream?.receive(completion: completion)
        }
    }
}

extension Publishers {
    struct RetryWhen<Upstream: Publisher>: Publisher {
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure

        private let upstream: Upstream
        private let max: Int
        private let delay: DispatchQueue.SchedulerTimeType.Stride
        private let predicate: (Result<Output, Failure>, Int) -> AnyPublisher<Bool, Never>

        init(
            upstream: Upstream,
            max: Int,
            delay: DispatchQueue.SchedulerTimeType.Stride,
            predicate: @escaping (Result<Output, Failure>, Int) -> AnyPublisher<Bool, Never>
        ) {
            self.upstream = upstream
            self.max = max
            self.delay = delay
            self.predicate = predicate
        }

        public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            let retrySubscriber = RetryWhenSubscriber(
                upstream: upstream,
                max: max,
                delay: delay,
                predicate: predicate,
                downstream: subscriber
            )
            subscriber.receive(subscription: retrySubscriber)
        }
    }
}
//extension Publisher {
//    func retryWhen(
//        max: Int = .max,
//        delay: DispatchQueue.SchedulerTimeType.Stride = 0,
//        _ predicate: @escaping (Result<Output, Failure>, Int) -> AnyPublisher<Bool, Never>
//    ) -> AnyPublisher<Output, Failure> {
//        Deferred {
//            self._retry(tryCount: 0, max: max, delay: delay, predicate: predicate)
//        }
//        .eraseToAnyPublisher()
//    }
//
//    private func _retry(
//        tryCount: Int,
//        max: Int,
//        delay: DispatchQueue.SchedulerTimeType.Stride,
//        predicate: @escaping (Result<Output, Failure>, Int) -> AnyPublisher<Bool, Never>
//    ) -> AnyPublisher<Output, Failure> {
//        return self.first()
//            .flatMap { value -> AnyPublisher<Output, Failure> in
//                return predicate(.success(value), tryCount)
//                    .flatMap { shouldRetry -> AnyPublisher<Output, Failure> in
//                        if shouldRetry && tryCount < max {
//                            return self._retry(tryCount: tryCount + 1, max: max, delay: delay, predicate: predicate)
//                                .delay(for: delay, scheduler: DispatchQueue.main)
//                                .eraseToAnyPublisher()
//                        } else {
//                            return Just(value)
//                                .setFailureType(to: Failure.self)
//                                .eraseToAnyPublisher()
//                        }
//                    }
//                    .eraseToAnyPublisher()
//            }
//            .catch { error -> AnyPublisher<Output, Failure> in
//                return predicate(.failure(error), tryCount)
//                    .flatMap { shouldRetry -> AnyPublisher<Output, Failure> in
//                        if shouldRetry && tryCount < max {
//                            return self._retry(tryCount: tryCount + 1, max: max, delay: delay, predicate: predicate)
//                                .delay(for: delay, scheduler: DispatchQueue.main)
//                                .eraseToAnyPublisher()
//                        } else {
//                            return Fail(error: error).eraseToAnyPublisher()
//                        }
//                    }
//                    .eraseToAnyPublisher()
//            }
//            .eraseToAnyPublisher()
//    }
//}
