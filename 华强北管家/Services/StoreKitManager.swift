import StoreKit
import SwiftUI

@Observable
final class StoreKitManager {

    // MARK: - Properties

    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading: Bool = false

    private var updateListenerTask: Task<Void, Never>?

    // MARK: - Computed

    var isSubscribed: Bool {
        !purchasedProductIDs.isEmpty
    }

    var isInTrialPeriod: Bool {
        guard let firstLaunch = UserDefaults.standard.object(forKey: AppConstants.firstLaunchDateKey) as? Date else {
            return true
        }
        let daysSinceLaunch = Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
        return daysSinceLaunch < AppConstants.trialDurationDays
    }

    var hasAccess: Bool {
        isSubscribed || isInTrialPeriod
    }

    var trialDaysRemaining: Int {
        guard let firstLaunch = UserDefaults.standard.object(forKey: AppConstants.firstLaunchDateKey) as? Date else {
            return AppConstants.trialDurationDays
        }
        let daysSinceLaunch = Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
        return max(0, AppConstants.trialDurationDays - daysSinceLaunch)
    }

    var monthlyProduct: Product? {
        products.first { $0.id == AppConstants.monthlyProductID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == AppConstants.yearlyProductID }
    }

    // MARK: - Init

    init() {
        // Record first launch
        if UserDefaults.standard.object(forKey: AppConstants.firstLaunchDateKey) == nil {
            UserDefaults.standard.set(Date(), forKey: AppConstants.firstLaunchDateKey)
        }

        updateListenerTask = Task { [weak self] in
            guard let self else { return }
            for await verificationResult in Transaction.updates {
                if case .verified(let transaction) = verificationResult {
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        do {
            let productIDs: Set<String> = [AppConstants.monthlyProductID, AppConstants.yearlyProductID]
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { return false }
            await transaction.finish()
            await updatePurchasedProducts()
            return true
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }

    // MARK: - Private

    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchased.insert(transaction.productID)
            }
        }
        self.purchasedProductIDs = purchased
    }
}
