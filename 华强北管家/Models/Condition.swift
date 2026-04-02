import SwiftData
import SwiftUI

@Model
final class Condition {
    var id: Foundation.UUID = Foundation.UUID()
    var code: String = ""
    var name: String = ""
    var colorHex: String = "39D353"
    var priceCoefficient: Double = 1.0
    var sortOrder: Int = 0

    @Relationship(deleteRule: .deny)
    var inventoryItems: [InventoryItem] = []

    init(code: String, name: String, colorHex: String, priceCoefficient: Double, sortOrder: Int) {
        self.id = Foundation.UUID()
        self.code = code
        self.name = name
        self.colorHex = colorHex
        self.priceCoefficient = priceCoefficient
        self.sortOrder = sortOrder
    }

    var color: Color {
        Color(hex: colorHex)
    }
}
