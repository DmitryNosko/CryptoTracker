import Combine
import UIKit

final class AppStoreViewModel: CombinableViewModel {
}

//MARK: - CombinableViewModel
extension AppStoreViewModel {
    struct Input {
        let didLoad: AnyPublisher<Void, Never>
        let didSelectItemAtIndexPath: AnyPublisher<IndexPath, Never>
    }

    final class Output: ObservableObject {
        @Published fileprivate(set) var cars: [AppStoreCellType] = []
        @Published fileprivate(set) var gadgets: [AppStoreCellType] = []
        @Published fileprivate(set) var carSetups: [AppStoreCellType] = []
    }

    func transform(input: Input, cancelBag: CancelBag) -> Output {
        let output = Output()

        // cars
        input.didLoad
            .map { _ in
                [
                    AppStoreCellType.car(Car(name: "Ferrari, Ferrari, Ferrari, Ferrari, Ferrari, Ferrari, Ferrari, Ferrari, Ferrari, Ferrari, Ferrari")),
                    AppStoreCellType.car(Car(name: "Ferrari")),
                    AppStoreCellType.car(Car(name: "Lamba")),
                    AppStoreCellType.car(Car(name: "Audi"))
                ]
            }
            .assign(to: \.cars, on: output)
            .store(in: cancelBag)

        // gadgets
        input.didLoad
            .map { _ in
                [
                    AppStoreCellType.gadget(Gadget(name: "iPhone 16 Pro Max", imageName: "")),
                    AppStoreCellType.gadget(Gadget(name: "iPhone 12 Pro", imageName: ""))
                ]
            }
            .assign(to: \.gadgets, on: output)
            .store(in: cancelBag)

        // carSetups
        input.didLoad
            .map { _ in
                [
                    AppStoreCellType.carSetup(CarSetup(setupSettings: "roof")),
                    AppStoreCellType.carSetup(CarSetup(setupSettings: "door")),
                    AppStoreCellType.carSetup(CarSetup(setupSettings: "wheels all wheels")),
                    AppStoreCellType.carSetup(CarSetup(setupSettings: "ring")),
                    AppStoreCellType.carSetup(CarSetup(setupSettings: "exchaut")),
                    AppStoreCellType.carSetup(CarSetup(setupSettings: "some special"))
                ]
            }
            .assign(to: \.carSetups, on: output)
            .store(in: cancelBag)

        // didSelectItemAtIndexPath carsetup
        input.didSelectItemAtIndexPath
            .filter { indexPath in
                let sectionOrder: [AppStoreSectionType] = [.car, .gadgets, .carSetup]
                return sectionOrder.indices.contains(indexPath.section) && sectionOrder[indexPath.section] == .carSetup
            }
            .withLatestFrom(Publishers.CombineLatest(output.$carSetups, output.$cars))
            .map { indexPath, items in
                let carSetups = items.0
                let cars = items.1

                output.cars = cars.enumerated().map { index, cell in
                    if case .car(var car) = cell {
                        if index == indexPath.item {
                            car.isSelected.toggle()
                        }
                        return AppStoreCellType.car(car)
                    }
                    return cell
                }

                return carSetups.enumerated().map { index, cell in
                    if case .carSetup(var carSetup) = cell {
                        if index == indexPath.item {
                            carSetup.isSelected.toggle()
                        }
                        return AppStoreCellType.carSetup(carSetup)
                    }
                    return cell
                }
            }
            .assign(to: \.carSetups, on: output)
            .store(in: cancelBag)

        return output
    }
}
