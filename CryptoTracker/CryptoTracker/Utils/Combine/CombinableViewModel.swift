import Foundation

protocol CombinableViewModel {
    associatedtype Input
    associatedtype Output
    func transform(input: Input, cancelBag: CancelBag) -> Output
}
