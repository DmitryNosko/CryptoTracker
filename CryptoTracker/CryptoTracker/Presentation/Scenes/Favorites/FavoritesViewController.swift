import UIKit
import Combine

final class FavoritesViewController: UIViewController {
    var viewModel: FavoritesViewModel!

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
private extension FavoritesViewController {
    func bindViewModel(_ viewModel: FavoritesViewModel) {
        let input = FavoritesViewModel.Input(
            didLoad: didLoad.eraseToAnyPublisher()
        )

        let output = viewModel.transform(
            input: input,
            cancelBag: cancelBag
        )
        render(output: output)
    }

    func render(output: FavoritesViewModel.Output) {}
}

// MARK: - Configure UI
private extension FavoritesViewController {
    func addSubviews() {}

    func setConstraints() {}

    func configureViews() {
        // view
        view.backgroundColor = .white
    }
}
