import SwiftData
import Foundation

// MARK: - Inventory Status

enum InventoryStatus: String, Codable, CaseIterable {
    case inStock = "inStock"
    case sold = "sold"
    case returned = "returned"

    var displayName: String {
        switch self {
        case .inStock: return "在库"
        case .sold: return "已售"
        case .returned: return "退货"
        }
    }

    var icon: String {
        switch self {
        case .inStock: return "shippingbox.fill"
        case .sold: return "cart.fill"
        case .returned: return "arrow.uturn.backward"
        }
    }
}

// MARK: - Inventory Item Model

@Model
final class InventoryItem {
    var id: Foundation.UUID = Foundation.UUID()
    var quantity: Int = 1
    var serialNumber: String = ""
    var costPrice: Double = 0
    var sellingPrice: Double = 0
    var status: InventoryStatus
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var note: String = ""

    var skuItem: SKUItem?
    var condition: Condition?
    var storageLocation: StorageLocation?

    // MARK: - Computed

    var profit: Double {
        (sellingPrice - costPrice) * Double(quantity)
    }

    var hasSN: Bool {
        !serialNumber.isEmpty
    }

    var locationPath: String {
        storageLocation?.fullPath ?? "未分配"
    }

    // MARK: - Init

    init(quantity: Int, serialNumber: String = "", costPrice: Double, sellingPrice: Double,
         skuItem: SKUItem?, condition: Condition?, storageLocation: StorageLocation? = nil, note: String = "", status: InventoryStatus = .inStock) {
        self.id = Foundation.UUID()
        self.status = status
        self.quantity = quantity
        self.serialNumber = serialNumber
        self.costPrice = costPrice
        self.sellingPrice = sellingPrice
        self.skuItem = skuItem
        self.condition = condition
        self.storageLocation = storageLocation
        self.note = note
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
