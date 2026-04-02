import SwiftUI
import SwiftData

struct InventoryDetailView: View {
    @Bindable var item: InventoryItem
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Status Badge
                HStack {
                    Image(systemName: item.status.icon)
                    Text(item.status.displayName)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Capsule().fill(statusColor.opacity(0.12)))

                // Info Cards
                infoCard("基本信息", items: [
                    ("SKU", item.skuItem?.name ?? "—"),
                    ("型号", item.skuItem?.model ?? "—"),
                    ("数量", "×\(item.quantity)"),
                ])

                infoCard("成色与序列号", items: {
                    var rows: [(String, String)] = [
                        ("成色", "\(item.condition?.code ?? "—") \(item.condition?.name ?? "")"),
                    ]
                    if !item.serialNumber.isEmpty {
                        rows.append(("SN 码", item.serialNumber))
                    }
                    return rows
                }())

                infoCard("价格", items: [
                    ("成本价", "¥\(String(format: "%.2f", item.costPrice))"),
                    ("售价", "¥\(String(format: "%.2f", item.sellingPrice))"),
                    ("毛利", "¥\(String(format: "%.2f", item.profit))"),
                ])

                infoCard("库位与时间", items: [
                    ("库位", item.locationPath),
                    ("入库时间", formatDate(item.createdAt)),
                    ("更新时间", formatDate(item.updatedAt)),
                ])

                if !item.note.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("备注").font(.system(size: 13, weight: .semibold)).foregroundStyle(AppTheme.textSecondary)
                        Text(item.note).font(.system(size: 14)).foregroundStyle(AppTheme.textPrimary)
                    }
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14).fill(AppTheme.cardBackground)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border, lineWidth: 1))
                    )
                }

                // Action Buttons
                if item.status == .inStock {
                    Button {
                        item.status = .sold
                        item.updatedAt = Date()
                        HapticManager.success()
                    } label: {
                        HStack {
                            Image(systemName: "cart.fill")
                            Text("标记为已售")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black).frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(AppTheme.techBlue).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else if item.status == .sold {
                    Button {
                        item.status = .returned
                        item.updatedAt = Date()
                        HapticManager.warning()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                            Text("退货")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.warningOrange).frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(AppTheme.warningOrange.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.warningOrange.opacity(0.3), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(16)
        }
        .background(AppTheme.background)
        .navigationTitle("库存详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var statusColor: Color {
        switch item.status {
        case .inStock: return AppTheme.accentGreen
        case .sold: return AppTheme.techBlue
        case .returned: return AppTheme.warningOrange
        }
    }

    private func infoCard(_ title: String, items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(AppTheme.textSecondary)
            ForEach(items, id: \.0) { label, value in
                HStack {
                    Text(label).font(.system(size: 14)).foregroundStyle(AppTheme.textTertiary)
                    Spacer()
                    Text(value).font(.system(size: 14, weight: .medium)).foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(AppTheme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border, lineWidth: 1))
        )
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    private func formatDate(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }
}
