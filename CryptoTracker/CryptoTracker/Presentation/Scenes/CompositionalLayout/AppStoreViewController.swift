import UIKit
import Combine

final class AppStoreViewController: UIViewController {
    var viewModel: AppStoreViewModel!

    // UI
    private var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())

    // Data
    typealias AppStoreDiffableDataSource = UICollectionViewDiffableDataSource<AppStoreSectionType, AppStoreCellType>
    private var dataSource: AppStoreDiffableDataSource!
    private var sectionConfigurationService = SectionConfigurationServiceImpl()

    // Snapshots
    private let sectionOrder: [AppStoreSectionType] = [.car, .gadgets, .carSetup]
    private var carItems: [AppStoreCellType] = []
    private var gadgetsItems: [AppStoreCellType] = []
    private var carSetupItems: [AppStoreCellType] = []

    // Combine
    private let cancelBag = CancelBag()
    private let didLoad = PassthroughSubject<Void, Never>()
    private let didSelectItemAtIndexPath = PassthroughSubject<IndexPath, Never>()

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
        confgiureViews()
    }
}

// MARK: - ViewModel Binding
private extension AppStoreViewController {
    func bindViewModel(_ viewModel: AppStoreViewModel) {
        let input = AppStoreViewModel.Input(
            didLoad: didLoad.eraseToAnyPublisher(),
            didSelectItemAtIndexPath: didSelectItemAtIndexPath.eraseToAnyPublisher()
        )

        let output = viewModel.transform(
            input: input,
            cancelBag: cancelBag
        )
        render(output: output)
    }

    func render(output: AppStoreViewModel.Output) {
        output.$cars
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.applyCarSnapshot(items)
            }
            .store(in: cancelBag)

        output.$gadgets
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.applyGadgetsSnapshot(items)
            }
            .store(in: cancelBag)

        output.$carSetups
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.applyCarSetupSnapshot(items)
            }
            .store(in: cancelBag)
    }
}

// MARK: - Configure UI
private extension AppStoreViewController {
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
            HeaderCollectionView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: HeaderCollectionView.reuseId
        )
        collectionView.register(
            CarCollectionViewCell.self,
            forCellWithReuseIdentifier: CarCollectionViewCell.reuseId
        )
        collectionView.register(
            GadgetCollectionViewCell.self,
            forCellWithReuseIdentifier: GadgetCollectionViewCell.reuseId
        )
        collectionView.register(
            CarSetupCollectionViewCell.self,
            forCellWithReuseIdentifier: CarSetupCollectionViewCell.reuseId
        )
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        configureDataSource()
    }
}

extension AppStoreViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        didSelectItemAtIndexPath.send(indexPath)
    }
}

private extension AppStoreViewController {
//    UICollectionViewCompositionalLayout
//    └── Section (.car)
//        ├── Header (будем добавлять)
//        └── Group (vertical)
//            ├── size: ширина = 100%, высота = estimated(44)
//            └── Subitems:
//                └── Item
//                    ├── size: ширина = 100%, высота = estimated(44)
//                    └── Ячейка (CarCollectionViewCell)
//
    func configureCollectionViewLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self else {
                return NSCollectionLayoutSection(
                    group: NSCollectionLayoutGroup(
                        layoutSize: NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1.0),
                            heightDimension: .fractionalHeight(1.0)
                        )
                    )
                )
            }

            let currentSection = self.dataSource.snapshot().sectionIdentifiers[sectionIndex]
            return self.sectionConfigurationService.buildSection(for: currentSection)
        }

        return layout
    }

    func configureDataSource() {
        /// Configure Item (Cell)
        dataSource = AppStoreDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .car(let car):
                guard
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: CarCollectionViewCell.reuseId,
                        for: indexPath
                    ) as? CarCollectionViewCell
                else {
                    return UICollectionViewCell()
                }

                cell.bind(with: car)

                return cell
            case .gadget(let gadget):
                guard
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: GadgetCollectionViewCell.reuseId,
                        for: indexPath
                    ) as? GadgetCollectionViewCell
                else {
                    return UICollectionViewCell()
                }

                cell.bind(with: gadget)

                return cell
            case .carSetup(let carSetup):
                guard
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: CarSetupCollectionViewCell.reuseId,
                        for: indexPath
                    ) as? CarSetupCollectionViewCell
                else {
                    return UICollectionViewCell()
                }

                cell.bind(with: carSetup)

                return cell
            }
        }

        /// Configure Section (Header)
        dataSource.supplementaryViewProvider = { [weak self] _, _, indexPath -> UICollectionReusableView? in
            guard
                let self,
                let view = self.collectionView.dequeueReusableSupplementaryView(
                    ofKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: HeaderCollectionView.reuseId,
                    for: indexPath
                ) as? HeaderCollectionView
            else {
                return UICollectionReusableView()
            }

            let dataSourceSection = dataSource.snapshot().sectionIdentifiers[indexPath.section]
            switch dataSourceSection {
            case .car:
                view.bind(with: "Cars in Stock")
            case .gadgets:
                view.bind(with: "Gadgets in Stock")
            case .carSetup:
                view.bind(with: "Car Setup")
            }

            return view
        }
    }

    private func ensureSectionOrder(_ snapshot: inout NSDiffableDataSourceSnapshot<AppStoreSectionType, AppStoreCellType>) {
        let currentSections = snapshot.sectionIdentifiers
        if currentSections != sectionOrder || currentSections.isEmpty {
            let itemsBySection = sectionOrder.reduce(into: [AppStoreSectionType: [AppStoreCellType]]()) { dict, section in
                if currentSections.contains(section) {
                    dict[section] = snapshot.itemIdentifiers(inSection: section)
                } else {
                    dict[section] = []
                }
            }
            snapshot.deleteAllItems()
            snapshot.appendSections(sectionOrder)
            for section in sectionOrder {
                if let items = itemsBySection[section], !items.isEmpty {
                    snapshot.appendItems(items, toSection: section)
                }
            }
        }
    }

    func applyCarSnapshot(_ items: [AppStoreCellType]) {
        carItems = items
        var snapshot = dataSource.snapshot()
        ensureSectionOrder(&snapshot)
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .car))
        snapshot.appendItems(items, toSection: .car)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    func applyGadgetsSnapshot(_ items: [AppStoreCellType]) {
        gadgetsItems = items
        var snapshot = dataSource.snapshot()
        ensureSectionOrder(&snapshot)
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .gadgets))
        snapshot.appendItems(items, toSection: .gadgets)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    func applyCarSetupSnapshot(_ items: [AppStoreCellType]) {
        carSetupItems = items
        var snapshot = dataSource.snapshot()
        ensureSectionOrder(&snapshot)
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .carSetup))
        snapshot.appendItems(carSetupItems, toSection: .carSetup)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
