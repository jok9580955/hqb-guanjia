import SwiftData
import Foundation

@Model
final class Category {
    var id: Foundation.UUID = Foundation.UUID()
    var name: String = ""
    var icon: String = "cpu"
    var sortOrder: Int = 0

    @Relationship(deleteRule: .nullify)
    var skuItems: [SKUItem] = []

    init(name: String, icon: String, sortOrder: Int = 0) {
        self.id = Foundation.UUID()
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
    }
}
