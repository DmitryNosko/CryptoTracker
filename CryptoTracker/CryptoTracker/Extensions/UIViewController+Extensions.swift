import UIKit
import Combine

extension UIViewController {
    func showAlert(_ type: AlertType) -> AnyPublisher<AlertActionType, Never> {
        Future<AlertActionType, Never> { promise in

            let preferredStyle = switch type {
            case .sort, .filter:
                UIAlertController.Style.actionSheet
            default:
                UIAlertController.Style.alert
            }

            let alert = UIAlertController(
                title: type.title,
                message: type.message,
                preferredStyle: preferredStyle
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
