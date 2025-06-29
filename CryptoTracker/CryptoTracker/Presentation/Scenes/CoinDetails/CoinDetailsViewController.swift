import UIKit
import Combine

final class CoinDetailsViewController: UIViewController {
    var viewModel: CoinDetailsViewModel!

    // UI

    // Combine
    private let cancelBag = CancelBag()
    private let didLoad = PassthroughSubject<Void, Never>()

    // LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        assemble()
        bindViewModel(viewModel)
        didLoad.send()
    }

    // Assemble
    private func assemble() {
        addSubviews()
        setConstraints()
        configureViews()
    }
}

// MARK: - ViewModel Binding
private extension CoinDetailsViewController {
    func bindViewModel(_ viewModel: CoinDetailsViewModel) {
        let input = CoinDetailsViewModel.Input(
            didLoad: didLoad.eraseToAnyPublisher()
        )

        let output = viewModel.transform(
            input: input,
            cancelBag: cancelBag
        )
        render(output: output)
    }

    func render(output: CoinDetailsViewModel.Output) {}
}

// MARK: - Configure UI
private extension CoinDetailsViewController {
    func addSubviews() {}

    func setConstraints() {}

    func configureViews() {
        // view
        view.backgroundColor = .white
    }
}
