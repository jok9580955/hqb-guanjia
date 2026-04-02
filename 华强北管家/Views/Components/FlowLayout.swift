import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for row in rows {
            height += row.maxHeight
        }
        height += CGFloat(max(0, rows.count - 1)) * lineSpacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for view in row.views {
                let size = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.maxHeight + lineSpacing
        }
    }

    private struct Row {
        var views: [LayoutSubview] = []
        var width: CGFloat = 0
        var maxHeight: CGFloat = 0
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        let maxWidth = proposal.width ?? .infinity

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentRow.width + size.width > maxWidth, !currentRow.views.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
            }
            currentRow.views.append(view)
            currentRow.width += size.width + spacing
            currentRow.maxHeight = max(currentRow.maxHeight, size.height)
        }
        if !currentRow.views.isEmpty {
            rows.append(currentRow)
        }
        return rows
    }
}
