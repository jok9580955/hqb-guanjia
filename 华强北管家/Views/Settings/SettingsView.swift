import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(StoreKitManager.self) private var storeKit
    @AppStorage("shopName") private var shopName: String = "华强北管家"
    @Environment(\.modelContext) private var modelContext

    @State private var showExportSheet = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            List {
                // Profile / Basic Setting
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppTheme.techBlue)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.techBlue.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Text("用户名")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.textPrimary)
                        
                        Spacer()
                        
                        TextField("输入用户名", text: $shopName)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                } header: {
                    Text("基本设置").foregroundStyle(AppTheme.textSecondary)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Subscription Status
                Section {
                    NavigationLink(destination: SubscriptionView()) {
                        HStack(spacing: 12) {
                            Image(systemName: storeKit.isSubscribed ? "crown.fill" : "gift.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(storeKit.isSubscribed ? AppTheme.neonGreen : AppTheme.warningOrange)
                                .frame(width: 32, height: 32)
                                .background((storeKit.isSubscribed ? AppTheme.neonGreen : AppTheme.warningOrange).opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(storeKit.isSubscribed ? "已订阅" : "免费试用")
                                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(AppTheme.textPrimary)
                                Text(storeKit.isSubscribed ? "感谢您的支持！" : "剩余 \(storeKit.trialDaysRemaining) 天")
                                    .font(.system(size: 12)).foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                }
                .listRowBackground(AppTheme.cardBackground)

                // Management
                Section {
                    NavigationLink(destination: ConditionManageView()) {
                        settingsRow(icon: "paintpalette.fill", title: "成色管理", color: AppTheme.purple)
                    }
                    NavigationLink(destination: CategoryManageView()) {
                        settingsRow(icon: "square.grid.2x2.fill", title: "品类管理", color: AppTheme.techBlue)
                    }
                    NavigationLink(destination: BrandManageView()) {
                        settingsRow(icon: "building.2.fill", title: "品牌管理", color: AppTheme.warningOrange)
                    }
                    NavigationLink(destination: StorageMapView()) {
                        settingsRow(icon: "map.fill", title: "库位管理", color: AppTheme.cyan)
                    }
                } header: {
                    Text("管理").foregroundStyle(AppTheme.textSecondary)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Data
                Section {
                    Button {
                        do {
                            let items = try modelContext.fetch(FetchDescriptor<InventoryItem>())
                            let csv = DataExportService.exportInventoryCSV(items: items)
                            if let url = DataExportService.saveToTempFile(content: csv, filename: "inventory_\(Date().timeIntervalSince1970).csv") {
                                exportURL = url
                                showExportSheet = true
                            }
                        } catch {
                            print("Fetch error: \(error)")
                        }
                    } label: {
                        settingsRow(icon: "square.and.arrow.up.fill", title: "导出库存数据", color: AppTheme.accentGreen)
                    }

                    Button {
                        do {
                            let skus = try modelContext.fetch(FetchDescriptor<SKUItem>())
                            let csv = DataExportService.exportSKUListCSV(skus: skus)
                            if let url = DataExportService.saveToTempFile(content: csv, filename: "sku_list_\(Date().timeIntervalSince1970).csv") {
                                exportURL = url
                                showExportSheet = true
                            }
                        } catch {
                            print("Fetch error: \(error)")
                        }
                    } label: {
                        settingsRow(icon: "list.bullet.rectangle.fill", title: "导出 SKU 列表", color: AppTheme.techBlue)
                    }
                } header: {
                    Text("数据").foregroundStyle(AppTheme.textSecondary)
                }
                .listRowBackground(AppTheme.cardBackground)

                // About
                Section {
                    HStack {
                        Text("版本").foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Text("1.0.0").foregroundStyle(AppTheme.textTertiary)
                    }
                } header: {
                    Text("关于").foregroundStyle(AppTheme.textSecondary)
                }
                .listRowBackground(AppTheme.cardBackground)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("设置")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func settingsRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(.white)
                .frame(width: 28, height: 28).background(color).clipShape(RoundedRectangle(cornerRadius: 6))
            Text(title).font(.system(size: 15)).foregroundStyle(AppTheme.textPrimary)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Category Management

struct CategoryManageView: View {
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Environment(\.modelContext) private var modelContext
    @State private var showForm = false
    @State private var editingCategory: Category?
    @State private var newName = ""
    @State private var newIcon = "cpu"

    private let iconOptions = ["cpu", "bolt.fill", "minus.rectangle.fill", "cable.connector",
                                "iphone", "memorychip", "battery.100", "camera.fill", "ellipsis.circle.fill",
                                "wrench.fill", "antenna.radiowaves.left.and.right", "speaker.wave.2.fill"]

    private var isEditing: Bool { editingCategory != nil }

    var body: some View {
        List {
            ForEach(categories) { cat in
                Button {
                    editingCategory = cat
                    newName = cat.name
                    newIcon = cat.icon
                    showForm = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: cat.icon).font(.system(size: 16)).foregroundStyle(AppTheme.techBlue)
                            .frame(width: 32, height: 32).background(AppTheme.techBlue.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
                        Text(cat.name).font(.system(size: 15)).foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Text("\(cat.skuItems.count) SKU").font(.system(size: 12)).foregroundStyle(AppTheme.textTertiary)
                        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(AppTheme.textTertiary)
                    }
                }
                .listRowBackground(AppTheme.cardBackground)
            }
            .onDelete { offsets in
                for i in offsets { modelContext.delete(categories[i]) }
            }
        }
        .listStyle(.insetGrouped).scrollContentBackground(.hidden).background(AppTheme.background)
        .navigationTitle("品类管理").navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editingCategory = nil
                    newName = ""
                    newIcon = "cpu"
                    showForm = true
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(AppTheme.neonGreen)
                }
            }
        }
        .sheet(isPresented: $showForm) {
            NavigationStack {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("品类名称").font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.textTertiary)
                        TextField("例: 电容", text: $newName).foregroundStyle(AppTheme.textPrimary)
                            .padding(10).background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.elevatedBackground))
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("图标").font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.textTertiary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button {
                                    newIcon = icon
                                    HapticManager.selection()
                                } label: {
                                    Image(systemName: icon).font(.system(size: 18))
                                        .foregroundStyle(newIcon == icon ? AppTheme.neonGreen : AppTheme.textSecondary)
                                        .frame(width: 44, height: 44)
                                        .background(RoundedRectangle(cornerRadius: 10)
                                            .fill(newIcon == icon ? AppTheme.neonGreen.opacity(0.1) : AppTheme.elevatedBackground))
                                }
                            }
                        }
                    }
                    Spacer()
                }
                .padding(16).background(AppTheme.background)
                .navigationTitle(isEditing ? "编辑品类" : "添加品类").navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("取消") { showForm = false }.foregroundStyle(AppTheme.textSecondary)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(isEditing ? "保存" : "添加") {
                            if let cat = editingCategory {
                                cat.name = newName
                                cat.icon = newIcon
                            } else {
                                let cat = Category(name: newName, icon: newIcon, sortOrder: categories.count)
                                modelContext.insert(cat)
                            }
                            newName = ""; showForm = false; HapticManager.success()
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(!newName.isEmpty ? AppTheme.neonGreen : AppTheme.textTertiary)
                        .disabled(newName.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Brand Management

struct BrandManageView: View {
    @Query(sort: \Brand.sortOrder) private var brands: [Brand]
    @Query private var skuItems: [SKUItem]
    @Environment(\.modelContext) private var modelContext
    @State private var showForm = false
    @State private var editingBrand: Brand?
    @State private var newName = ""

    private var isEditing: Bool { editingBrand != nil }

    var body: some View {
        List {
            ForEach(brands) { brand in
                Button {
                    editingBrand = brand
                    newName = brand.name
                    showForm = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "building.2.fill").font(.system(size: 16)).foregroundStyle(AppTheme.warningOrange)
                            .frame(width: 32, height: 32).background(AppTheme.warningOrange.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
                        Text(brand.name).font(.system(size: 15)).foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        let count = skuItems.filter { $0.brand == brand.name }.count
                        Text("\(count) SKU").font(.system(size: 12)).foregroundStyle(AppTheme.textTertiary)
                        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(AppTheme.textTertiary)
                    }
                }
                .listRowBackground(AppTheme.cardBackground)
            }
            .onDelete { offsets in
                for i in offsets { modelContext.delete(brands[i]) }
            }
        }
        .listStyle(.insetGrouped).scrollContentBackground(.hidden).background(AppTheme.background)
        .navigationTitle("品牌管理").navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editingBrand = nil
                    newName = ""
                    showForm = true
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(AppTheme.neonGreen)
                }
            }
        }
        .sheet(isPresented: $showForm) {
            NavigationStack {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("品牌名称").font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.textTertiary)
                        TextField("例: ST", text: $newName).foregroundStyle(AppTheme.textPrimary)
                            .padding(10).background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.elevatedBackground))
                    }
                    Spacer()
                }
                .padding(16).background(AppTheme.background)
                .navigationTitle(isEditing ? "编辑品牌" : "添加品牌").navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("取消") { showForm = false }.foregroundStyle(AppTheme.textSecondary)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(isEditing ? "保存" : "添加") {
                            saveBrand()
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(!newName.isEmpty ? AppTheme.neonGreen : AppTheme.textTertiary)
                        .disabled(newName.isEmpty)
                    }
                }
            }
            .presentationDetents([.fraction(0.3)])
        }
    }

    private func saveBrand() {
        if let brand = editingBrand {
            let oldName = brand.name
            brand.name = newName
            
            // Link string updates to maintain legacy connections
            let affectedSKUs = skuItems.filter { $0.brand == oldName }
            for sku in affectedSKUs {
                sku.brand = newName
            }
        } else {
            let brand = Brand(name: newName, sortOrder: brands.count)
            modelContext.insert(brand)
        }
        newName = ""
        showForm = false
        HapticManager.success()
    }
}
