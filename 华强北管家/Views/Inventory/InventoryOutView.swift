import SwiftUI
import SwiftData

struct InventoryOutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let sku: SKUItem

    @State private var selectedItems: Set<UUID> = []

    private var inStockItems: [InventoryItem] {
        sku.inventoryItems.filter { $0.status == .inStock }.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("选择出库项")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("已选 \(selectedItems.count)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.neonGreen)
                }
                .padding(16)

                if inStockItems.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "tray").font(.system(size: 40)).foregroundStyle(AppTheme.textTertiary)
                        Text("没有在库库存").font(.system(size: 15)).foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(inStockItems) { item in
                                outboundRow(item)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                // Bottom action
                VStack(spacing: 8) {
                    Divider().background(AppTheme.border)
                    Button(action: submitOutbound) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("确认出库 (\(selectedItems.count))")
                        }
                        .font(.system(size: 16, weight: .bold)).foregroundStyle(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(selectedItems.isEmpty ? AppTheme.textTertiary : AppTheme.techBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(selectedItems.isEmpty)
                    .padding(.horizontal, 16).padding(.bottom, 8)
                }
            }
            .background(AppTheme.background)
            .navigationTitle("出库")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }.foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private func outboundRow(_ item: InventoryItem) -> some View {
        let isSelected = selectedItems.contains(item.id)
        return Button {
            if isSelected { selectedItems.remove(item.id) } else { selectedItems.insert(item.id) }
            HapticManager.selection()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? AppTheme.techBlue : AppTheme.textTertiary)

                ConditionBadgeView(condition: item.condition)

                VStack(alignment: .leading, spacing: 3) {
                    if !item.serialNumber.isEmpty {
                        Text("SN: \(item.serialNumber)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(AppTheme.warningOrange)
                    }
                    Text(item.locationPath)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("×\(item.quantity)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("¥\(String(format: "%.0f", item.sellingPrice))")
                        .font(.system(size: 12)).foregroundStyle(AppTheme.accentGreen)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppTheme.techBlue.opacity(0.08) : AppTheme.cardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? AppTheme.techBlue.opacity(0.3) : AppTheme.border, lineWidth: 1))
            )
        }
    }

    private func submitOutbound() {
        for item in inStockItems where selectedItems.contains(item.id) {
            item.status = .sold
            item.updatedAt = Date()
        }
        HapticManager.success()
        dismiss()
    }
}
