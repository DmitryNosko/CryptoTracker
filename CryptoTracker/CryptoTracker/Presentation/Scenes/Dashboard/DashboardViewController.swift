import UIKit
import Combine

final class DashboardViewController: UITabBarController, UITabBarControllerDelegate {
    var viewModel: DashboardViewModel!

    // Combine
    private let cancelBag = CancelBag()
    private let willAppear = PassthroughSubject<Void, Never>()

    // LifeCycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        assemble()
        bindViewModel(viewModel)
        willAppear.send()
    }

    // Assemble
    private func assemble() {
        addSubviews()
        setConstraints()
        configureViews()
    }
}

// MARK: - ViewModel Binding
private extension DashboardViewController {
    func bindViewModel(_ viewModel: DashboardViewModel) {
        let input = DashboardViewModel.Input(
            willAppear: willAppear.eraseToAnyPublisher()
        )

        let output = viewModel.transform(
            input: input,
            cancelBag: cancelBag
        )
        render(output: output)
    }

    func render(output: DashboardViewModel.Output) {}
}

// MARK: - Configure UI
private extension DashboardViewController {
    func addSubviews() {}

    func setConstraints() {}

    func configureViews() {
        // tabBar
        tabBar.tintColor = .dodgerBlue
        tabBar.backgroundColor = .mercury
    }
}
