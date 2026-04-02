import SwiftUI
import SwiftData

struct SKUDetailView: View {
    @Bindable var sku: SKUItem
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Condition.sortOrder) private var conditions: [Condition]

    @State private var showInbound = false
    @State private var showOutbound = false
    @State private var showEdit = false
    @State private var selectedConditionFilter: Condition?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // SKU Info Card
                infoCard

                // Action Buttons
                actionButtons

                // Condition Filter
                conditionFilter

                // Inventory List
                inventoryList
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AppTheme.background)
        .navigationTitle(sku.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showEdit = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundStyle(AppTheme.techBlue)
                }
            }
        }
        .sheet(isPresented: $showInbound) {
            InventoryInView(sku: sku)
        }
        .sheet(isPresented: $showOutbound) {
            InventoryOutView(sku: sku)
        }
        .sheet(isPresented: $showEdit) {
            SKUEditView(sku: sku)
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: sku.category?.icon ?? "shippingbox")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.techBlue)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.techBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(sku.model)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    HStack(spacing: 8) {
                        if !sku.brand.isEmpty {
                            Label(sku.brand, systemImage: "building.2")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        if !sku.barcode.isEmpty {
                            Label(sku.barcode, systemImage: "barcode")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }

                Spacer()

                if sku.needsSNTracking {
                    Image(systemName: "number.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.warningOrange)
                }
            }

            Divider().background(AppTheme.border)

            // Stats Row
            HStack {
                statItem(title: "总库存", value: "\(sku.totalStock)", color: AppTheme.accentGreen)
                Spacer()
                statItem(title: "库存总值", value: "¥\(String(format: "%.0f", sku.totalValue))", color: AppTheme.techBlue)
                Spacer()
                statItem(title: "参考价", value: "¥\(String(format: "%.0f", sku.referencePrice))", color: AppTheme.purple)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))
        )
    }

    private func statItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showInbound = true
                HapticManager.medium()
            } label: {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("入库")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.neonGreen)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                showOutbound = true
                HapticManager.medium()
            } label: {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("出库")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.techBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.techBlue.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.techBlue.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Condition Filter

    private var conditionFilter: some View {
        FlowLayout(spacing: 8, lineSpacing: 8) {
            filterChip(name: "全部", isSelected: selectedConditionFilter == nil) {
                selectedConditionFilter = nil
            }

            ForEach(conditions) { condition in
                let count = sku.inventoryItems
                    .filter { $0.condition == condition && $0.status == .inStock }
                    .reduce(0) { $0 + $1.quantity }
                if count > 0 {
                    filterChip(
                        name: "\(condition.code) (\(count))",
                        color: condition.color,
                        isSelected: selectedConditionFilter == condition
                    ) {
                        selectedConditionFilter = condition
                    }
                }
            }
        }
    }

    private func filterChip(name: String, color: Color = AppTheme.neonGreen, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? .black : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.1))
                )
        }
    }

    // MARK: - Inventory List

    private var inventoryList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("库存明细")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)

            if filteredInventory.isEmpty {
                Text("暂无在库记录")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(20)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(filteredInventory) { item in
                    NavigationLink(destination: InventoryDetailView(item: item)) {
                        inventoryRow(item)
                    }
                }
            }
        }
    }

    private func inventoryRow(_ item: InventoryItem) -> some View {
        HStack(spacing: 10) {
            ConditionBadgeView(condition: item.condition)

            VStack(alignment: .leading, spacing: 3) {
                if !item.serialNumber.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "number")
                            .font(.system(size: 10))
                        Text(item.serialNumber)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .foregroundStyle(AppTheme.warningOrange)
                }

                HStack(spacing: 8) {
                    Label(item.locationPath, systemImage: "mappin")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)

                    Text(item.createdAt, format: .dateTime.month().day())
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("×\(item.quantity)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("¥\(String(format: "%.0f", item.sellingPrice))")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.accentGreen)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
        )
    }

    private var filteredInventory: [InventoryItem] {
        var items = sku.inventoryItems.filter { $0.status == .inStock }
        if let filter = selectedConditionFilter {
            items = items.filter { $0.condition == filter }
        }
        return items.sorted { $0.createdAt > $1.createdAt }
    }
}
