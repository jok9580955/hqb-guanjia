import SwiftUI
import SwiftData

struct ConditionManageView: View {
    @Query(sort: \Condition.sortOrder) private var conditions: [Condition]
    @Environment(\.modelContext) private var modelContext
    @State private var showAdd = false
    @State private var editingCondition: Condition?
    @State private var newCode = ""
    @State private var newName = ""
    @State private var newColorHex = "39D353"
    @State private var newCoefficient = "1.0"

    private let colorOptions = [
        "39D353", "58A6FF", "F0C000", "F0883E", "F85149",
        "BC8CFF", "39D2C0", "FF6B9D", "79C0FF", "D2A8FF",
    ]

    var body: some View {
        List {
            ForEach(conditions) { condition in
                Button {
                    editingCondition = condition
                    newCode = condition.code
                    newName = condition.name
                    newColorHex = condition.colorHex
                    newCoefficient = String(format: "%.1f", condition.priceCoefficient)
                    showAdd = true
                } label: {
                    HStack(spacing: 12) {
                        Circle().fill(condition.color).frame(width: 12, height: 12)
                            .shadow(color: condition.color.opacity(0.5), radius: 3)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(condition.code).font(.system(size: 15, weight: .bold)).foregroundStyle(condition.color)
                                Text(condition.name).font(.system(size: 14)).foregroundStyle(AppTheme.textPrimary)
                            }
                            Text("价格系数: \(String(format: "%.0f%%", condition.priceCoefficient * 100))")
                                .font(.system(size: 11)).foregroundStyle(AppTheme.textTertiary)
                        }

                        Spacer()

                        Text("\(condition.inventoryItems.count)")
                            .font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.textSecondary)
                        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(AppTheme.textTertiary)
                    }
                }
                .listRowBackground(AppTheme.cardBackground)
            }
            .onDelete { offsets in
                for i in offsets {
                    let c = conditions[i]
                    if c.inventoryItems.isEmpty {
                        modelContext.delete(c)
                        HapticManager.medium()
                    } else {
                        HapticManager.error()
                    }
                }
            }
        }
        .listStyle(.insetGrouped).scrollContentBackground(.hidden).background(AppTheme.background)
        .navigationTitle("成色管理").navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editingCondition = nil
                    newCode = ""; newName = ""; newColorHex = "39D353"; newCoefficient = "1.0"
                    showAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(AppTheme.neonGreen)
                }
            }
        }
        .sheet(isPresented: $showAdd) { conditionForm }
    }

    private var conditionForm: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("代码").font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.textTertiary)
                            TextField("A+", text: $newCode).foregroundStyle(AppTheme.textPrimary)
                                .padding(10).background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.elevatedBackground))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("名称").font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.textTertiary)
                            TextField("原装全新", text: $newName).foregroundStyle(AppTheme.textPrimary)
                                .padding(10).background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.elevatedBackground))
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("颜色").font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.textTertiary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                            ForEach(colorOptions, id: \.self) { hex in
                                Button {
                                    newColorHex = hex
                                    HapticManager.selection()
                                } label: {
                                    Circle().fill(Color(hex: hex)).frame(width: 36, height: 36)
                                        .overlay(Circle().stroke(newColorHex == hex ? .white : .clear, lineWidth: 2))
                                        .shadow(color: Color(hex: hex).opacity(newColorHex == hex ? 0.5 : 0), radius: 4)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("价格系数 (0.0 - 1.0)").font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.textTertiary)
                        TextField("1.0", text: $newCoefficient).keyboardType(.decimalPad).foregroundStyle(AppTheme.textPrimary)
                            .padding(10).background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.elevatedBackground))
                    }

                    // Preview
                    HStack(spacing: 8) {
                        Circle().fill(Color(hex: newColorHex)).frame(width: 10, height: 10)
                        Text(newCode.isEmpty ? "?" : newCode).font(.system(size: 14, weight: .bold)).foregroundStyle(Color(hex: newColorHex))
                        Text(newName).font(.system(size: 13)).foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(12).frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: newColorHex).opacity(0.1)))
                }
                .padding(16)
            }
            .background(AppTheme.background)
            .navigationTitle(editingCondition != nil ? "编辑成色" : "添加成色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { showAdd = false }.foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { saveCondition() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(!newCode.isEmpty && !newName.isEmpty ? AppTheme.neonGreen : AppTheme.textTertiary)
                        .disabled(newCode.isEmpty || newName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveCondition() {
        let coeff = Double(newCoefficient) ?? 1.0
        if let c = editingCondition {
            c.code = newCode; c.name = newName; c.colorHex = newColorHex; c.priceCoefficient = coeff
        } else {
            let c = Condition(code: newCode, name: newName, colorHex: newColorHex, priceCoefficient: coeff, sortOrder: conditions.count)
            modelContext.insert(c)
        }
        showAdd = false
        HapticManager.success()
    }
}
