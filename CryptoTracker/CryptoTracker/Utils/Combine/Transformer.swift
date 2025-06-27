protocol Transformer: Equatable {
    associatedtype Input
    associatedtype Output

    func transform(input: Input) -> Output
}
