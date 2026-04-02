import SwiftUI

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let gradient: LinearGradient

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 32, height: 32)
                    .background(gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
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
}

#Preview {
    HStack {
        StatCardView(title: "总 SKU", value: "128", icon: "shippingbox.fill", gradient: AppTheme.greenGradient)
        StatCardView(title: "总库存", value: "3,456", icon: "cube.fill", gradient: AppTheme.blueGradient)
    }
    .padding()
    .background(AppTheme.background)
}
