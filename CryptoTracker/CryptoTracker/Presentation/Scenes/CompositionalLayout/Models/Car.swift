import Foundation

struct Car: Hashable {
    let id = UUID()
    let name: String
    var isSelected = false

//    static func == (lhs: Self, rhs: Self) -> Bool {
//        return false
//    }
}
