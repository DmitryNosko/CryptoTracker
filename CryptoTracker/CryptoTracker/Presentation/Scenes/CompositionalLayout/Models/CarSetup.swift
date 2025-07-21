import Foundation

struct CarSetup: Hashable {
    let id = UUID()
    let setupSettings: String
    var isSelected: Bool = false

//    static func == (lhs: Self, rhs: Self) -> Bool {
//        return false
//    }
}
