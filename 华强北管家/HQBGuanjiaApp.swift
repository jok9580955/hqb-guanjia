import SwiftUI
import SwiftData

@main
struct HQBGuanjiaApp: App {
    @State private var storeKitManager = StoreKitManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeKitManager)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [
            Category.self,
            Brand.self,
            SKUItem.self,
            InventoryItem.self,
            StorageLocation.self,
            Condition.self,
        ])
    }
}
