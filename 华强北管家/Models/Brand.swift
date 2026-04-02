import SwiftData
import Foundation

@Model
final class Brand {
    var id: Foundation.UUID = Foundation.UUID()
    var name: String = ""
    var sortOrder: Int = 0

    init(name: String, sortOrder: Int = 0) {
        self.id = Foundation.UUID()
        self.name = name
        self.sortOrder = sortOrder
    }
}
