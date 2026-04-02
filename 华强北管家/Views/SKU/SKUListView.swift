import SwiftUI
import SwiftData

enum FilterMode: String, CaseIterable {
    case category = "品类"
    case brand = "品牌"
}

struct SKUListView: View {
    @Query(sort: \SKUItem.createdAt, order: .reverse) private var allSKUs: [SKUItem]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Brand.sortOrder) private var managedBrands: [Brand]
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreKitManager.self) private var storeKit

    @State private var searchText = ""
    @State private var filterMode: FilterMode = .category
    @State private var selectedCategory: Category?
    @State private var selectedBrand: String?
    @State private var showAddSKU = false
    @State private var showPaywall = false

    private var allBrands: [String] {
        let managed = managedBrands.map { $0.name }
        let dynamic = Array(Set(allSKUs.compactMap { $0.brand.isEmpty ? nil : $0.brand }))
        
        var combined = managed
        let dynamicOnly = dynamic.filter { !managed.contains($0) }.sorted()
        combined.append(contentsOf: dynamicOnly)
        
        return combined
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar

                // Filter Mode + Chips
                filterBar

                // SKU List
                if filteredSKUs.isEmpty {
                    emptyState
                } else {
                    skuList
                }
            }
            .background(AppTheme.background)
            .navigationTitle("库存管理")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: handleAddSKU) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.neonGreen)
                    }
                }
            }
            .sheet(isPresented: $showAddSKU) {
                SKUEditView(sku: nil)
            }
            .sheet(isPresented: $showPaywall) {
                SubscriptionView()
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.textTertiary)

            TextField("搜索名称、型号、条码...", text: $searchText)
                .foregroundStyle(AppTheme.textPrimary)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 6) {
            // Segmented picker
            Picker("筛选方式", selection: $filterMode) {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 6)

            // Filter chips
            FlowLayout(spacing: 8, lineSpacing: 8) {
                if filterMode == .category {
                    filterChip(name: "全部", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                        HapticManager.selection()
                    }
                    ForEach(categories) { cat in
                        filterChip(name: cat.name, icon: cat.icon, isSelected: selectedCategory == cat) {
                            selectedCategory = cat
                            HapticManager.selection()
                        }
                    }
                } else {
                    filterChip(name: "全部", icon: "tag", isSelected: selectedBrand == nil) {
                        selectedBrand = nil
                        HapticManager.selection()
                    }
                    ForEach(allBrands, id: \.self) { brand in
                        filterChip(name: brand, icon: "building.2", isSelected: selectedBrand == brand) {
                            selectedBrand = brand
                            HapticManager.selection()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func filterChip(name: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(name)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? AppTheme.neonGreen.opacity(0.15) : AppTheme.cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected ? AppTheme.neonGreen.opacity(0.5) : AppTheme.border,
                                lineWidth: 1
                            )
                    )
            )
            .foregroundStyle(isSelected ? AppTheme.neonGreen : AppTheme.textSecondary)
        }
    }

    // MARK: - SKU List

    private var skuList: some View {
        List {
            ForEach(filteredSKUs) { sku in
                NavigationLink(destination: SKUDetailView(sku: sku)) {
                    SKURowView(sku: sku)
                }
                .listRowBackground(AppTheme.secondaryBackground)
                .listRowSeparatorTint(AppTheme.border)
            }
            .onDelete(perform: deleteSKU)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: searchText.isEmpty ? "shippingbox" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary)

            Text(searchText.isEmpty ? "还没有 SKU" : "未找到匹配的 SKU")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            if searchText.isEmpty {
                Button(action: handleAddSKU) {
                    HStack {
                        Image(systemName: "plus")
                        Text("添加第一个 SKU")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppTheme.neonGreen)
                    .clipShape(Capsule())
                }
            }

            Spacer()
        }
    }

    // MARK: - Filtered

    private var filteredSKUs: [SKUItem] {
        var result = allSKUs

        if filterMode == .category {
            if let cat = selectedCategory {
                result = result.filter { $0.category == cat }
            }
        } else {
            if let brand = selectedBrand {
                result = result.filter { $0.brand == brand }
            }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.model.lowercased().contains(query) ||
                $0.barcode.lowercased().contains(query) ||
                $0.brand.lowercased().contains(query)
            }
        }

        return result
    }

    // MARK: - Actions

    private func handleAddSKU() {
        if storeKit.hasAccess || allSKUs.count < AppConstants.freeSKULimit {
            showAddSKU = true
        } else {
            showPaywall = true
        }
    }

    private func deleteSKU(at offsets: IndexSet) {
        for index in offsets {
            let sku = filteredSKUs[index]
            modelContext.delete(sku)
        }
        HapticManager.medium()
    }
}

// MARK: - SKU Row

struct SKURowView: View {
    let sku: SKUItem

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: sku.category?.icon ?? "shippingbox")
                .font(.system(size: 18))
                .foregroundStyle(AppTheme.techBlue)
                .frame(width: 40, height: 40)
                .background(AppTheme.techBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(sku.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(sku.model)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)

                    if !sku.brand.isEmpty {
                        Text("·")
                            .foregroundStyle(AppTheme.textTertiary)
                        Text(sku.brand)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textTertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Stock Badge
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(sku.totalStock)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(sku.totalStock <= AppConstants.lowStockThreshold && sku.totalStock > 0
                        ? AppTheme.warningOrange
                        : AppTheme.accentGreen)

                // Condition dots
                HStack(spacing: 3) {
                    ForEach(sku.stockByCondition.prefix(3), id: \.condition.id) { item in
                        ConditionBadgeView(condition: item.condition, showName: false, compact: true)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
