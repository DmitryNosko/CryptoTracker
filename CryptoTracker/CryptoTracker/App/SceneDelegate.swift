import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var appContext: AppContext = AppContext()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard
            let windowScene = (scene as? UIWindowScene)
        else {
            return
        }

        window = UIWindow(windowScene: windowScene)

        let rootViewController = RootBuilderImpl(appContext: appContext)
            .build()
        let rootNavigationViewController = UINavigationController(rootViewController: rootViewController)
        rootNavigationViewController.setNavigationBarHidden(true, animated: false)
        window?.rootViewController = rootNavigationViewController
        window?.makeKeyAndVisible()
    }
}
