import UIKit
import Combine

final class HomeViewController: UIViewController {
    var viewModel: HomeViewModel!

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
private extension HomeViewController {
    func bindViewModel(_ viewModel: HomeViewModel) {
        let input = HomeViewModel.Input(
            didLoad: didLoad.eraseToAnyPublisher()
        )

        let output = viewModel.transform(
            input: input,
            cancelBag: cancelBag
        )
        render(output: output)
    }

    func render(output: HomeViewModel.Output) {}
}

// MARK: - Configure UI
private extension HomeViewController {
    func addSubviews() {}

    func setConstraints() {}

    func configureViews() {
        // view
        view.backgroundColor = .white
    }
}
