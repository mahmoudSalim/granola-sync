import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case history = "Export History"
    case settings = "Settings"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.bottom.50percent"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape"
        case .about: return "info.circle"
        }
    }
}

struct MainWindow: View {
    @EnvironmentObject var appState: AppState
    @State private var selection: SidebarItem = .dashboard

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            switch selection {
            case .dashboard:
                DashboardView()
            case .history:
                ExportHistoryView()
            case .settings:
                SettingsView()
            case .about:
                AboutView()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .sheet(isPresented: $appState.needsSetup) {
            SetupWizardView()
        }
    }
}
