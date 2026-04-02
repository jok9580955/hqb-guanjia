import SwiftData
import Foundation

@Model
final class StorageLocation {
    var id: Foundation.UUID = Foundation.UUID()
    var shelf: String = ""
    var layer: Int = 1
    var drawer: String = ""
    var barcode: String = ""

    @Relationship(deleteRule: .nullify)
    var inventoryItems: [InventoryItem] = []

    // MARK: - Computed

    var fullPath: String {
        "\(shelf)-\(layer)-\(drawer)"
    }

    var itemCount: Int {
        inventoryItems.filter { $0.status == .inStock }.count
    }

    var totalQuantity: Int {
        inventoryItems.filter { $0.status == .inStock }.reduce(0) { $0 + $1.quantity }
    }

    // MARK: - Init

    init(shelf: String, layer: Int, drawer: String) {
        self.id = Foundation.UUID()
        self.shelf = shelf
        self.layer = layer
        self.drawer = drawer
        self.barcode = "LOC-\(shelf)-\(layer)-\(drawer)"
    }
}
