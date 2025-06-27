import Foundation

final class AppContext {
    private var factories: [String: () -> Any] = [:]

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
            fatalError("No registered factory for \(key)")
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
