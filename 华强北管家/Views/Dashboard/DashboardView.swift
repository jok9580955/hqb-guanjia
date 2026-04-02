import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var skuItems: [SKUItem]
    @Query private var inventoryItems: [InventoryItem]
    @Query(sort: \Condition.sortOrder) private var conditions: [Condition]
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreKitManager.self) private var storeKit
    @AppStorage("shopName") private var shopName: String = "华强北管家"
    
    @State private var showRenameAlert = false
    @State private var renameInput = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Banner
                    profileSection
                    // Trial Banner
                    if !storeKit.isSubscribed && storeKit.isInTrialPeriod {
                        trialBanner
                    }

                    // Stats Grid
                    statsGrid

                    // Condition Distribution
                    conditionSection

                    // Low Stock Alerts
                    lowStockSection

                    // Recent Activity
                    recentSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(AppTheme.background)
            .navigationTitle(shopName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("修改用户名", isPresented: $showRenameAlert) {
                TextField("请输入新的用户名", text: $renameInput)
                Button("取消", role: .cancel) { }
                Button("保存") {
                    if !renameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        shopName = renameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            } message: {
                Text("输入一个新的名称，该名称将显示在主页顶部。")
            }
        }
    }

    // MARK: - Profile Banner
    
    private var profileSection: some View {
        Button {
            renameInput = shopName
            showRenameAlert = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [AppTheme.neonGreen.opacity(0.2), AppTheme.techBlue.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(colors: [AppTheme.neonGreen, AppTheme.techBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(shopName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                    
                    Text("欢迎回来")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()
                
                Image(systemName: "pencil")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Trial Banner

    private var trialBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.neonGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text("免费试用中")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("剩余 \(storeKit.trialDaysRemaining) 天")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            NavigationLink(destination: SubscriptionView()) {
                Text("升级")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(AppTheme.neonGreen)
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.neonGreen.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.neonGreen.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCardView(
                title: "总 SKU",
                value: "\(skuItems.count)",
                icon: "shippingbox.fill",
                gradient: AppTheme.greenGradient
            )

            StatCardView(
                title: "总库存",
                value: formatNumber(totalInStock),
                icon: "cube.fill",
                gradient: AppTheme.blueGradient
            )

            StatCardView(
                title: "库存总值",
                value: "¥\(formatNumber(Int(totalValue)))",
                icon: "yensign.circle.fill",
                gradient: AppTheme.orangeGradient
            )

            StatCardView(
                title: "今日入库",
                value: "\(todayInboundCount)",
                icon: "arrow.down.circle.fill",
                gradient: AppTheme.purpleGradient
            )
        }
    }

    // MARK: - Condition Distribution

    private var conditionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("成色分布", icon: "paintpalette.fill")

            HStack(spacing: 0) {
                ForEach(conditions) { condition in
                    let count = inventoryItems.filter { $0.condition == condition && $0.status == .inStock }
                        .reduce(0) { $0 + $1.quantity }
                    if count > 0 {
                        VStack(spacing: 6) {
                            Text("\(count)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(condition.color)

                            Text(condition.code)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                if totalInStock == 0 {
                    Text("暂无库存数据")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Low Stock Alerts

    private var lowStockSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("低库存预警", icon: "exclamationmark.triangle.fill")

            if lowStockItems.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accentGreen)
                    Text("所有 SKU 库存充足")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(lowStockItems.prefix(5)) { sku in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.warningOrange)

                            Text(sku.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Text("仅剩 \(sku.totalStock)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.dangerRed)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        if sku.id != lowStockItems.prefix(5).last?.id {
                            Divider()
                                .background(AppTheme.border)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                )
            }
        }
    }

    // MARK: - Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("最近入库", icon: "clock.fill")

            if recentItems.isEmpty {
                Text("暂无入库记录")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppTheme.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                    )
            } else {
                VStack(spacing: 0) {
                    ForEach(recentItems.prefix(5)) { item in
                        HStack(spacing: 10) {
                            ConditionBadgeView(condition: item.condition, compact: true)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.skuItem?.name ?? "未知")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .lineLimit(1)

                                Text(item.createdAt, style: .relative)
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.textTertiary)
                            }

                            Spacer()

                            Text("×\(item.quantity)")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.techBlue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                        if item.id != recentItems.prefix(5).last?.id {
                            Divider()
                                .background(AppTheme.border)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                )
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSecondary)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private var totalInStock: Int {
        inventoryItems.filter { $0.status == .inStock }.reduce(0) { $0 + $1.quantity }
    }

    private var totalValue: Double {
        inventoryItems.filter { $0.status == .inStock }.reduce(0) { $0 + $1.sellingPrice * Double($1.quantity) }
    }

    private var todayInboundCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return inventoryItems.filter { $0.createdAt >= today && $0.status == .inStock }.reduce(0) { $0 + $1.quantity }
    }

    private var lowStockItems: [SKUItem] {
        skuItems.filter { $0.totalStock > 0 && $0.totalStock <= AppConstants.lowStockThreshold }
            .sorted { $0.totalStock < $1.totalStock }
    }

    private var recentItems: [InventoryItem] {
        inventoryItems.sorted { $0.createdAt > $1.createdAt }
    }

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
