import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("看板", systemImage: "chart.bar.fill")
                }
                .tag(0)

            SKUListView()
                .tabItem {
                    Label("库存", systemImage: "shippingbox.fill")
                }
                .tag(1)

            BarcodeScannerView()
                .tabItem {
                    Label("扫码", systemImage: "barcode.viewfinder")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(AppTheme.neonGreen)
    }
}

#Preview {
    MainTabView()
}
