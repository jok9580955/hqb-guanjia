import SwiftUI
import SwiftData

struct InventoryInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Condition.sortOrder) private var conditions: [Condition]
    @Query(sort: [SortDescriptor(\StorageLocation.shelf), SortDescriptor(\StorageLocation.layer)])
    private var locations: [StorageLocation]

    let sku: SKUItem

    @State private var quantity = "1"
    @State private var serialNumber = ""
    @State private var costPrice = ""
    @State private var sellingPrice = ""
    @State private var selectedCondition: Condition?
    @State private var selectedLocation: StorageLocation?
    @State private var note = ""
    @State private var isContinuousMode = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    skuInfoBanner
                    conditionSelector
                    quantityAndSNSection
                    pricingSection
                    locationSection
                    noteSection
                    continuousModeToggle
                    submitButton
                }
                .padding(16)
            }
            .background(AppTheme.background)
            .navigationTitle("入库")
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

    private var skuInfoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: sku.category?.icon ?? "shippingbox")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.techBlue)
                .frame(width: 40, height: 40)
                .background(AppTheme.techBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(sku.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(AppTheme.textPrimary)
                Text(sku.model).font(.system(size: 12)).foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(AppTheme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border, lineWidth: 1))
        )
    }

    private var conditionSelector: some View {
        sectionCard(title: "成色 *") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                ForEach(conditions) { condition in
                    Button {
                        selectedCondition = condition
                        if sku.referencePrice > 0 {
                            sellingPrice = String(format: "%.0f", sku.referencePrice * condition.priceCoefficient)
                        }
                        HapticManager.selection()
                    } label: {
                        VStack(spacing: 6) {
                            Circle().fill(condition.color).frame(width: 12, height: 12)
                                .shadow(color: condition.color.opacity(0.5), radius: selectedCondition == condition ? 4 : 0)
                            Text(condition.code).font(.system(size: 14, weight: .bold))
                                .foregroundStyle(selectedCondition == condition ? condition.color : AppTheme.textSecondary)
                            Text(condition.name).font(.system(size: 10)).foregroundStyle(AppTheme.textTertiary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedCondition == condition ? condition.color.opacity(0.1) : AppTheme.elevatedBackground)
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedCondition == condition ? condition.color.opacity(0.5) : Color.clear, lineWidth: 1.5))
                        )
                    }
                }
            }
        }
    }

    private var quantityAndSNSection: some View {
        sectionCard(title: "数量与序列号") {
            HStack(spacing: 12) {
                fieldView("数量", text: $quantity, keyboard: .numberPad)
                if sku.needsSNTracking {
                    fieldView("SN 码 *", text: $serialNumber, color: AppTheme.warningOrange)
                }
            }
        }
    }

    private var pricingSection: some View {
        sectionCard(title: "价格") {
            HStack(spacing: 12) {
                fieldView("成本价", text: $costPrice, keyboard: .decimalPad)
                fieldView("售价", text: $sellingPrice, keyboard: .decimalPad)
            }
        }
    }

    private var locationSection: some View {
        sectionCard(title: "库位") {
            if locations.isEmpty {
                Text("还没有库位，请先在设置中添加").font(.system(size: 13)).foregroundStyle(AppTheme.textTertiary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(locations) { loc in
                            Button {
                                selectedLocation = loc
                                HapticManager.selection()
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(selectedLocation == loc ? AppTheme.neonGreen : AppTheme.textTertiary)
                                    Text(loc.fullPath).font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(selectedLocation == loc ? AppTheme.neonGreen : AppTheme.textSecondary)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedLocation == loc ? AppTheme.neonGreen.opacity(0.1) : AppTheme.elevatedBackground)
                                        .overlay(RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedLocation == loc ? AppTheme.neonGreen.opacity(0.5) : Color.clear, lineWidth: 1))
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private var noteSection: some View {
        sectionCard(title: "备注") {
            TextField("入库备注（可选）", text: $note)
                .foregroundStyle(AppTheme.textPrimary).padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.elevatedBackground))
        }
    }

    private var continuousModeToggle: some View {
        Toggle(isOn: $isContinuousMode) {
            HStack(spacing: 8) {
                Image(systemName: "repeat").foregroundStyle(AppTheme.techBlue)
                Text("连续入库模式").font(.system(size: 14, weight: .medium)).foregroundStyle(AppTheme.textPrimary)
            }
        }
        .tint(AppTheme.neonGreen).padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(AppTheme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border, lineWidth: 1))
        )
    }

    private var submitButton: some View {
        Button(action: submitInbound) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                Text("确认入库")
            }
            .font(.system(size: 16, weight: .bold)).foregroundStyle(.black)
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(canSubmit ? AppTheme.neonGreen : AppTheme.textTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!canSubmit)
    }

    // MARK: - Helpers

    private func sectionCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(AppTheme.textSecondary)
            content()
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(AppTheme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border, lineWidth: 1))
        )
    }

    private func fieldView(_ title: String, text: Binding<String>, keyboard: UIKeyboardType = .default, color: Color = AppTheme.textTertiary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(color)
            TextField("", text: text).keyboardType(keyboard)
                .foregroundStyle(AppTheme.textPrimary).padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.elevatedBackground))
        }
    }

    private var canSubmit: Bool {
        selectedCondition != nil && (Int(quantity) ?? 0) > 0 &&
        (!sku.needsSNTracking || !serialNumber.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private func submitInbound() {
        let item = InventoryItem(
            quantity: Int(quantity) ?? 1,
            serialNumber: serialNumber.trimmingCharacters(in: .whitespaces),
            costPrice: Double(costPrice) ?? 0,
            sellingPrice: Double(sellingPrice) ?? 0,
            skuItem: sku, condition: selectedCondition,
            storageLocation: selectedLocation, note: note
        )
        modelContext.insert(item)
        HapticManager.success()
        if isContinuousMode { quantity = "1"; serialNumber = ""; note = "" } else { dismiss() }
    }
}
