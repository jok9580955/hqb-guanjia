import SwiftUI

struct ConditionBadgeView: View {
    let condition: Condition?
    var showName: Bool = true
    var compact: Bool = false

    var body: some View {
        if let condition {
            HStack(spacing: 4) {
                Circle()
                    .fill(condition.color)
                    .frame(width: compact ? 6 : 8, height: compact ? 6 : 8)

                if showName {
                    Text(condition.code)
                        .font(.system(size: compact ? 10 : 12, weight: .semibold))
                        .foregroundStyle(condition.color)
                }
            }
            .padding(.horizontal, compact ? 6 : 8)
            .padding(.vertical, compact ? 2 : 4)
            .background(
                Capsule()
                    .fill(condition.color.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(condition.color.opacity(0.3), lineWidth: 1)
                    )
            )
        } else {
            Text("未知")
                .font(.system(size: compact ? 10 : 12))
                .foregroundStyle(AppTheme.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(AppTheme.elevatedBackground)
                )
        }
    }
}

// MARK: - Condition Dot (minimal)

struct ConditionDotView: View {
    let condition: Condition

    var body: some View {
        Circle()
            .fill(condition.color)
            .frame(width: 10, height: 10)
            .shadow(color: condition.color.opacity(0.5), radius: 3)
    }
}

#Preview {
    HStack {
        ConditionBadgeView(condition: nil)
    }
    .padding()
    .background(AppTheme.background)
}
