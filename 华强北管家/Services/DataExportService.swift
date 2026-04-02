import SwiftData
import Foundation

struct DataExportService {

    // MARK: - Export Inventory to CSV

    static func exportInventoryCSV(items: [InventoryItem]) -> String {
        var csv = "\u{FEFF}SKU名称,型号,品牌,SN码,成色,数量,成本价,售价,库位,状态,入库时间,备注\n"

        for item in items {
            let skuName = item.skuItem?.name ?? ""
            let model = item.skuItem?.model ?? ""
            let brand = item.skuItem?.brand ?? ""
            let sn = item.serialNumber
            let condition = item.condition?.name ?? ""
            let qty = "\(item.quantity)"
            let cost = String(format: "%.2f", item.costPrice)
            let sell = String(format: "%.2f", item.sellingPrice)
            let location = item.locationPath
            let status = item.status.displayName
            let date = Self.dateFormatter.string(from: item.createdAt)
            let note = item.note.replacingOccurrences(of: ",", with: "，")

            csv += "\(skuName),\(model),\(brand),\(sn),\(condition),\(qty),\(cost),\(sell),\(location),\(status),\(date),\(note)\n"
        }

        return csv
    }

    // MARK: - Export SKUs to CSV

    static func exportSKUListCSV(skus: [SKUItem]) -> String {
        var csv = "\u{FEFF}SKU名称,型号,品牌,条码,参考价,总库存,库存总值,需要SN追踪,品类\n"

        for sku in skus {
            let name = sku.name
            let model = sku.model
            let brand = sku.brand
            let barcode = sku.barcode
            let price = String(format: "%.2f", sku.referencePrice)
            let stock = "\(sku.totalStock)"
            let value = String(format: "%.2f", sku.totalValue)
            let needsSN = sku.needsSNTracking ? "是" : "否"
            let category = sku.category?.name ?? "未分类"

            csv += "\(name),\(model),\(brand),\(barcode),\(price),\(stock),\(value),\(needsSN),\(category)\n"
        }

        return csv
    }

    // MARK: - Save to Temp File

    static func saveToTempFile(content: String, filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to save CSV: \(error)")
            return nil
        }
    }

    // MARK: - Private

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()
}
