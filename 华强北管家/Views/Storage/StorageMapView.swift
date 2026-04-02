import SwiftUI
import SwiftData

struct StorageMapView: View {
    @Query(sort: [SortDescriptor(\StorageLocation.shelf), SortDescriptor(\StorageLocation.layer)])
    private var locations: [StorageLocation]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddSheet = false
    @State private var newShelf = ""
    @State private var newLayer = "1"
    @State private var newDrawer = ""

    private var groupedLocations: [(String, [StorageLocation])] {
        let dict = Dictionary(grouping: locations) { $0.shelf }
        return dict.sorted { $0.key < $1.key }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if locations.isEmpty {
                    emptyState
                } else {
                    ForEach(groupedLocations, id: \.0) { shelf, locs in
                        shelfSection(shelf: shelf, locations: locs)
                    }
                }
            }
            .padding(16)
        }
        .background(AppTheme.background)
        .navigationTitle("库位管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(AppTheme.neonGreen)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) { addLocationSheet }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map").font(.system(size: 48)).foregroundStyle(AppTheme.textTertiary)
            Text("还没有库位").font(.system(size: 16, weight: .medium)).foregroundStyle(AppTheme.textSecondary)
            Text("添加货架、层和抽屉来管理存储位置").font(.system(size: 13)).foregroundStyle(AppTheme.textTertiary)
            Button { showAddSheet = true } label: {
                HStack { Image(systemName: "plus"); Text("添加库位") }
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(.black)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(AppTheme.neonGreen).clipShape(Capsule())
            }
        }
        .padding(.top, 60)
    }

    private func shelfSection(shelf: String, locations: [StorageLocation]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "cabinet.fill").foregroundStyle(AppTheme.techBlue)
                Text("货架 \(shelf)").font(.system(size: 15, weight: .bold)).foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(locations.count) 个库位").font(.system(size: 12)).foregroundStyle(AppTheme.textTertiary)
            }

            let byLayer = Dictionary(grouping: locations) { $0.layer }.sorted { $0.key < $1.key }

            ForEach(byLayer, id: \.0) { layer, locs in
                VStack(alignment: .leading, spacing: 6) {
                    Text("第 \(layer) 层").font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.textSecondary)
                        .padding(.leading, 8)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(locs) { loc in
                            VStack(spacing: 4) {
                                Text(loc.drawer).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.textPrimary)
                                Text("\(loc.totalQuantity)").font(.system(size: 11)).foregroundStyle(
                                    loc.totalQuantity > 0 ? AppTheme.accentGreen : AppTheme.textTertiary
                                )
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10).fill(AppTheme.elevatedBackground)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border, lineWidth: 1))
                            )
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(loc)
                                    HapticManager.medium()
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(AppTheme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border, lineWidth: 1))
        )
    }

    private var addLocationSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("货架号").font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.textTertiary)
                    TextField("例: A", text: $newShelf).foregroundStyle(AppTheme.textPrimary)
                        .padding(10).background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.elevatedBackground))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("层号").font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.textTertiary)
                    TextField("例: 1", text: $newLayer).keyboardType(.numberPad).foregroundStyle(AppTheme.textPrimary)
                        .padding(10).background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.elevatedBackground))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("抽屉号").font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.textTertiary)
                    TextField("例: 01", text: $newDrawer).foregroundStyle(AppTheme.textPrimary)
                        .padding(10).background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.elevatedBackground))
                }
                Spacer()
            }
            .padding(16)
            .background(AppTheme.background)
            .navigationTitle("添加库位")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { showAddSheet = false }.foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        let loc = StorageLocation(shelf: newShelf, layer: Int(newLayer) ?? 1, drawer: newDrawer)
                        modelContext.insert(loc)
                        newShelf = ""; newLayer = "1"; newDrawer = ""
                        showAddSheet = false
                        HapticManager.success()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(!newShelf.isEmpty && !newDrawer.isEmpty ? AppTheme.neonGreen : AppTheme.textTertiary)
                    .disabled(newShelf.isEmpty || newDrawer.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
