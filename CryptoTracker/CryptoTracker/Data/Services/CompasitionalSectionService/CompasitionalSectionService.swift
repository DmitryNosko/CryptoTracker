import UIKit

protocol CollectionViewSectionType {
    func makeSection() -> NSCollectionLayoutSection
}

protocol SectionConfigurationService {
    func buildSection<T: CollectionViewSectionType>(for sectionType: T) -> NSCollectionLayoutSection
}

final class SectionConfigurationServiceImpl: SectionConfigurationService {
    func buildSection<T: CollectionViewSectionType>(
        for sectionType: T
    ) -> NSCollectionLayoutSection {
        return sectionType.makeSection()
    }
}
