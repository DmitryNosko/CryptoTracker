import UIKit
import Combine

final class RootViewController: UIViewController {
    var viewModel: RootViewModel!

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
private extension RootViewController {
    func bindViewModel(_ viewModel: RootViewModel) {
        let input = RootViewModel.Input(
            didLoad: didLoad.eraseToAnyPublisher()
        )

        let output = viewModel.transform(
            input: input,
            cancelBag: cancelBag
        )
        render(output: output)
    }

    func render(output: RootViewModel.Output) {}
}

// MARK: - Configure UI
private extension RootViewController {
    func addSubviews() {}

    func setConstraints() {}

    func configureViews() {
        // view
        view.backgroundColor = .white
    }
}
