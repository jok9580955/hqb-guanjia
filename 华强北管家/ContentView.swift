import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var hasSeeded = UserDefaults.standard.bool(forKey: AppConstants.hasSeededDefaultDataKey)

    var body: some View {
        MainTabView()
            .onAppear {
                if !hasSeeded {
                    seedDefaultData()
                }
            }
    }

    private func seedDefaultData() {
        // Seed default conditions
        for (index, item) in AppConstants.defaultConditions.enumerated() {
            let condition = Condition(
                code: item.code,
                name: item.name,
                colorHex: item.colorHex,
                priceCoefficient: item.coefficient,
                sortOrder: index
            )
            modelContext.insert(condition)
        }

        // Seed default categories
        for (index, item) in AppConstants.defaultCategories.enumerated() {
            let category = Category(
                name: item.name,
                icon: item.icon,
                sortOrder: index
            )
            modelContext.insert(category)
        }

        UserDefaults.standard.set(true, forKey: AppConstants.hasSeededDefaultDataKey)
        hasSeeded = true
    }
}

#Preview {
    ContentView()
}
