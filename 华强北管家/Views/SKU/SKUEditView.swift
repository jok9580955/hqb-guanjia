import SwiftUI
import SwiftData

struct SKUEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Brand.sortOrder) private var brands: [Brand]

    let sku: SKUItem?

    @State private var name = ""
    @State private var model = ""
    @State private var brand = ""
    @State private var barcode = ""
    @State private var referencePrice = ""
    @State private var needsSNTracking = false
    @State private var selectedCategory: Category?
    @State private var notes = ""

    var isEditing: Bool { sku != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Basic Info
                    formSection(title: "基本信息") {
                        formField("名称 *", text: $name, placeholder: "例：STM32F103C8T6")
                        formField("型号 *", text: $model, placeholder: "例：LQFP-48")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            formField("品牌", text: $brand, placeholder: "例：ST / TI / 国产")
                            
                            if !brands.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(brands) { b in
                                            Button {
                                                brand = b.name
                                                HapticManager.selection()
                                            } label: {
                                                Text(b.name)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        Capsule()
                                                            .fill(brand == b.name ? AppTheme.warningOrange.opacity(0.15) : AppTheme.elevatedBackground)
                                                            .overlay(
                                                                Capsule().stroke(brand == b.name ? AppTheme.warningOrange.opacity(0.5) : AppTheme.border, lineWidth: 1)
                                                            )
                                                    )
                                                    .foregroundStyle(brand == b.name ? AppTheme.warningOrange : AppTheme.textSecondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        formField("条码", text: $barcode, placeholder: "扫码或手动输入")
                    }

                    // Category
                    formSection(title: "品类") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories) { cat in
                                    Button {
                                        selectedCategory = cat
                                        HapticManager.selection()
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 12))
                                            Text(cat.name)
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(selectedCategory == cat
                                                    ? AppTheme.neonGreen.opacity(0.15)
                                                    : AppTheme.elevatedBackground)
                                                .overlay(
                                                    Capsule()
                                                        .stroke(
                                                            selectedCategory == cat
                                                                ? AppTheme.neonGreen.opacity(0.5)
                                                                : AppTheme.border,
                                                            lineWidth: 1
                                                        )
                                                )
                                        )
                                        .foregroundStyle(selectedCategory == cat ? AppTheme.neonGreen : AppTheme.textSecondary)
                                    }
                                }
                            }
                        }
                    }

                    // Pricing & Tracking
                    formSection(title: "价格与追踪") {
                        formField("参考售价", text: $referencePrice, placeholder: "0", keyboard: .decimalPad)

                        Toggle(isOn: $needsSNTracking) {
                            HStack(spacing: 8) {
                                Image(systemName: "number.circle.fill")
                                    .foregroundStyle(AppTheme.warningOrange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("SN 码追踪")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text("入库时需要录入序列号")
                                        .font(.system(size: 11))
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                            }
                        }
                        .tint(AppTheme.neonGreen)
                        .padding(.vertical, 4)
                    }

                    // Notes
                    formSection(title: "备注") {
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .padding(8)
                            .foregroundStyle(AppTheme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppTheme.elevatedBackground)
                            )
                    }
                }
                .padding(16)
            }
            .background(AppTheme.background)
            .navigationTitle(isEditing ? "编辑 SKU" : "新建 SKU")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "保存" : "创建") { save() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(canSave ? AppTheme.neonGreen : AppTheme.textTertiary)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadData)
        }
    }

    // MARK: - Form Helpers

    private func formSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: 12) {
                content()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.cardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border, lineWidth: 1))
            )
        }
    }

    private func formField(_ title: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textTertiary)

            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .foregroundStyle(AppTheme.textPrimary)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.elevatedBackground)
                )
        }
    }

    // MARK: - Logic

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func loadData() {
        guard let sku else { return }
        name = sku.name
        model = sku.model
        brand = sku.brand
        barcode = sku.barcode
        referencePrice = sku.referencePrice > 0 ? String(format: "%.0f", sku.referencePrice) : ""
        needsSNTracking = sku.needsSNTracking
        selectedCategory = sku.category
        notes = sku.notes
    }

    private func save() {
        let price = Double(referencePrice) ?? 0

        if let sku {
            // Update
            sku.name = name.trimmingCharacters(in: .whitespaces)
            sku.model = model.trimmingCharacters(in: .whitespaces)
            sku.brand = brand.trimmingCharacters(in: .whitespaces)
            sku.barcode = barcode.trimmingCharacters(in: .whitespaces)
            sku.referencePrice = price
            sku.needsSNTracking = needsSNTracking
            sku.category = selectedCategory
            sku.notes = notes
        } else {
            // Create
            let newSKU = SKUItem(
                name: name.trimmingCharacters(in: .whitespaces),
                model: model.trimmingCharacters(in: .whitespaces),
                brand: brand.trimmingCharacters(in: .whitespaces),
                barcode: barcode.trimmingCharacters(in: .whitespaces),
                referencePrice: price,
                needsSNTracking: needsSNTracking,
                category: selectedCategory
            )
            newSKU.notes = notes
            modelContext.insert(newSKU)
        }

        HapticManager.success()
        dismiss()
    }
}
