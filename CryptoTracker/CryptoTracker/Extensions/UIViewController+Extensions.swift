import UIKit
import Combine

extension UIViewController {
    func showAlert(_ type: AlertType) -> AnyPublisher<AlertActionType, Never> {
        Future<AlertActionType, Never> { promise in
            let alert = UIAlertController(
                title: type.title,
                message: type.message,
                preferredStyle: UIAlertController.Style.alert
            )
            type.actions.forEach { action in
                alert.addAction(
                    UIAlertAction(
                        title: action.title,
                        style: action.style
                    ) { _ in
                        promise(.success(action.result))
                    }
                )
            }

            self.present(alert, animated: true)
        }
        .eraseToAnyPublisher()
    }
}
