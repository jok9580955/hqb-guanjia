import SwiftData
import Foundation

@Model
final class SKUItem {
    var id: Foundation.UUID = Foundation.UUID()
    var name: String = ""
    var model: String = ""
    var brand: String = ""
    var barcode: String = ""
    var referencePrice: Double = 0
    var needsSNTracking: Bool = false
    var notes: String = ""
    var createdAt: Date = Date()

    var category: Category?

    @Relationship(deleteRule: .cascade)
    var inventoryItems: [InventoryItem] = []

    // MARK: - Computed Properties

    var totalStock: Int {
        inventoryItems.filter { $0.status == .inStock }.reduce(0) { $0 + $1.quantity }
    }

    var totalValue: Double {
        inventoryItems.filter { $0.status == .inStock }.reduce(0) { $0 + $1.sellingPrice * Double($1.quantity) }
    }

    var totalCost: Double {
        inventoryItems.filter { $0.status == .inStock }.reduce(0) { $0 + $1.costPrice * Double($1.quantity) }
    }

    var stockByCondition: [(condition: Condition, count: Int)] {
        let inStockItems = inventoryItems.filter { $0.status == .inStock }
        var result: [(condition: Condition, count: Int)] = []
        var seen: Set<UUID> = []
        for item in inStockItems {
            guard let cond = item.condition, !seen.contains(cond.id) else { continue }
            seen.insert(cond.id)
            let count = inStockItems.filter { $0.condition?.id == cond.id }.reduce(0) { $0 + $1.quantity }
            result.append((condition: cond, count: count))
        }
        return result.sorted { $0.condition.sortOrder < $1.condition.sortOrder }
    }

    // MARK: - Init

    init(name: String, model: String, brand: String = "", barcode: String = "",
         referencePrice: Double = 0, needsSNTracking: Bool = false, category: Category? = nil) {
        self.id = Foundation.UUID()
        self.name = name
        self.model = model
        self.brand = brand
        self.barcode = barcode
        self.referencePrice = referencePrice
        self.needsSNTracking = needsSNTracking
        self.category = category
        self.createdAt = Date()
    }
}
