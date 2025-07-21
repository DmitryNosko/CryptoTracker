import UIKit
import Combine

final class OnboardingViewController: UIViewController {
    // UI
    private let collectionView = UICollectionView()

    // LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        assemble()
    }

    // Assemble
    private func assemble() {
        addSubviews()
        setConstraints()
        confgiureViews()
    }
}

// MARK: - Configure UI
private extension OnboardingViewController {
    func addSubviews() {
        view.addSubview(collectionView)
    }

    func setConstraints() {
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func confgiureViews() {
        // collectionView
        collectionView.collectionViewLayout = configureCollectionViewLayout()
        collectionView.register(
            CarCollectionViewCell.self,
            forCellWithReuseIdentifier: CarCollectionViewCell.reuseId
        )
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        configureDataSource()
    }
}

extension OnboardingViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        print("didSelectItemAt")
        print("didSelectItemAt")
        print("didSelectItemAt")
        print("didSelectItemAt")
    }
}
