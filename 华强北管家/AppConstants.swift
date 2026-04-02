import Foundation

enum AppConstants {

    // MARK: - Default Conditions (成色等级)

    static let defaultConditions: [(code: String, name: String, colorHex: String, coefficient: Double)] = [
        ("A+", "原装全新", "39D353", 1.0),
        ("A",  "原装拆机", "58A6FF", 0.7),
        ("B+", "国产全新", "F0C000", 0.5),
        ("B",  "翻新件",   "F0883E", 0.4),
        ("C",  "维修件",   "F85149", 0.2),
    ]

    // MARK: - Default Categories (默认品类)

    static let defaultCategories: [(name: String, icon: String)] = [
        ("电容",   "bolt.fill"),
        ("电阻",   "minus.rectangle.fill"),
        ("MCU",    "cpu"),
        ("排线",   "cable.connector"),
        ("屏幕",   "iphone"),
        ("主板",   "memorychip"),
        ("电池",   "battery.100"),
        ("摄像头", "camera.fill"),
        ("其他",   "ellipsis.circle.fill"),
    ]

    // MARK: - Subscription

    static let monthlyProductID = "com.hqbguanjia.monthly"
    static let yearlyProductID = "com.hqbguanjia.yearly"
    static let trialDurationDays = 7
    static let freeSKULimit = 10

    // MARK: - UserDefaults Keys

    static let firstLaunchDateKey = "firstLaunchDate"
    static let hasSeededDefaultDataKey = "hasSeededDefaultData"

    // MARK: - Low Stock Threshold

    static let lowStockThreshold = 5
}
