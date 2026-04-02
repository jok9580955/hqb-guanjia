import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(StoreKitManager.self) private var storeKit
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.neonGreen)
                        .shadow(color: AppTheme.neonGreen.opacity(0.4), radius: 12)

                    Text("解锁全部功能")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("无限 SKU · 无限库存 · 数据导出 · 持续更新")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Features
                VStack(alignment: .leading, spacing: 14) {
                    featureRow(icon: "infinity", title: "无限 SKU", desc: "不受数量限制")
                    featureRow(icon: "barcode.viewfinder", title: "扫码找货", desc: "极速定位库存")
                    featureRow(icon: "number.circle.fill", title: "SN 追踪", desc: "高价值配件全程追溯")
                    featureRow(icon: "paintpalette.fill", title: "成色管理", desc: "自定义成色价格体系")
                    featureRow(icon: "square.and.arrow.up", title: "数据导出", desc: "CSV 格式随时导出")
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16).fill(AppTheme.cardBackground)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))
                )

                // Plans
                VStack(spacing: 12) {
                    if let monthly = storeKit.monthlyProduct {
                        planCard(product: monthly, accent: AppTheme.techBlue, badge: nil)
                    }
                    if let yearly = storeKit.yearlyProduct {
                        planCard(product: yearly, accent: AppTheme.neonGreen, badge: "推荐 · 省30%")
                    }

                    if storeKit.products.isEmpty && !storeKit.isLoading {
                        VStack(spacing: 8) {
                            Text("月订阅 ¥18 / 年订阅 ¥128")
                                .font(.system(size: 15, weight: .semibold)).foregroundStyle(AppTheme.textPrimary)
                            Text("订阅产品加载中...请稍后重试")
                                .font(.system(size: 13)).foregroundStyle(AppTheme.textTertiary)
                        }
                        .padding(16)
                    }
                }

                // Restore
                Button {
                    Task { await storeKit.restorePurchases() }
                } label: {
                    Text("恢复购买")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSecondary)
                        .underline()
                }

                // Terms
                Text("订阅将在到期时自动续订，除非在到期前至少24小时关闭自动续订。可在 App Store 账户设置中管理订阅。")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding(16)
        }
        .background(AppTheme.background)
        .task { await storeKit.loadProducts() }
    }

    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16)).foregroundStyle(AppTheme.neonGreen)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(AppTheme.textPrimary)
                Text(desc).font(.system(size: 12)).foregroundStyle(AppTheme.textTertiary)
            }
        }
    }

    private func planCard(product: Product, accent: Color, badge: String?) -> some View {
        Button {
            Task {
                isPurchasing = true
                _ = try? await storeKit.purchase(product)
                isPurchasing = false
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let badge {
                        Text(badge).font(.system(size: 11, weight: .bold)).foregroundStyle(accent)
                    }
                    Text(product.displayName).font(.system(size: 16, weight: .bold)).foregroundStyle(AppTheme.textPrimary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.system(size: 18, weight: .bold)).foregroundStyle(accent)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14).fill(accent.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.3), lineWidth: 1.5))
            )
        }
        .disabled(isPurchasing)
    }
}
