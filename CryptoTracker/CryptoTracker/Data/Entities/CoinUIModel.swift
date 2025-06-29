import Foundation
import UIKit

struct CoinUIModel: Identifiable, Equatable {
    let id: String
    let name: String
    let price: Double
    let imageURL: URL?
    let isFavorite: Bool

    init(from model: CoinModel, isFavorite: Bool) {
        self.id = model.id
        self.name = model.name
        self.price = model.price
        self.imageURL = model.imageURL
        self.isFavorite = isFavorite
    }

    var formattedPrice: String {
        "$\(String(format: "%.2f", price))"
    }
}
