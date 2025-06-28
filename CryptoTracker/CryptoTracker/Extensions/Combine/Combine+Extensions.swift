import Foundation
import Combine

// MARK: - AnyCancellable
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

// MARK: - WithLatestFrom
extension Publishers {
    public struct WithLatestFrom<Upstream: Publisher, Other: Publisher>:
        Publisher where Upstream.Failure == Other.Failure
    {
        public typealias Output = (Upstream.Output, Other.Output)
        public typealias Failure = Upstream.Failure

        private let upstream: Upstream
        private let other: Other

        init(upstream: Upstream, other: Other) {
            self.upstream = upstream
            self.other = other
        }

        public func receive<S: Subscriber>(subscriber: S)
        where S.Failure == Failure, S.Input == Output
        {
            let merged = mergedStream(upstream, other)
            let result = resultStream(from: merged)
            result.subscribe(subscriber)
        }
    }
}

extension Publishers.WithLatestFrom {
    enum MergedElement {
        case upstream1(Upstream.Output)
        case upstream2(Other.Output)
    }

    typealias ScanResult =
    (value1: Upstream.Output?,
     value2: Other.Output?, shouldEmit: Bool)

    func mergedStream(_ upstream1: Upstream, _ upstream2: Other)
    -> AnyPublisher<MergedElement, Failure>
    {
        let mergedElementUpstream1 = upstream1
            .map { MergedElement.upstream1($0) }
        let mergedElementUpstream2 = upstream2
            .map { MergedElement.upstream2($0) }
        return mergedElementUpstream1
            .merge(with: mergedElementUpstream2)
            .eraseToAnyPublisher()
    }

    func resultStream(
        from mergedStream: AnyPublisher<MergedElement, Failure>
    ) -> AnyPublisher<Output, Failure>
    {
        mergedStream
            .scan(nil) {
                (prevResult: ScanResult?,
                 mergedElement: MergedElement) -> ScanResult? in

                var newValue1: Upstream.Output?
                var newValue2: Other.Output?
                let shouldEmit: Bool

                switch mergedElement {
                case .upstream1(let v):
                    newValue1 = v
                    shouldEmit = prevResult?.value2 != nil
                case .upstream2(let v):
                    newValue2 = v
                    shouldEmit = false
                }

                return ScanResult(value1: newValue1 ?? prevResult?.value1,
                                  value2: newValue2 ?? prevResult?.value2,
                                  shouldEmit: shouldEmit)
            }
            .compactMap { $0 }
            .filter { $0.shouldEmit }
            .map { Output($0.value1!, $0.value2!) }
            .eraseToAnyPublisher()
    }
}

extension Publisher {
    func withLatestFrom<Other: Publisher>(_ other: Other)
    -> Publishers.WithLatestFrom<Self, Other>
    {
        return .init(upstream: self, other: other)
    }
}
