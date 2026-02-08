import SwiftUI
import SwiftData

@main
struct RaquelReadsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            DailyCheckIn.self,
            StreakRecord.self,
            Book.self,
            ReadingSession.self,
            Goal.self,
            UserSettings.self,
        ])
    }
}

// MARK: - Root Tab View

struct ContentView: View {
    @State private var selectedTab: Tab = .checkIn

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases) { tab in
                tab.view
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
    }
}

// MARK: - Tabs

enum Tab: String, CaseIterable, Identifiable {
    case checkIn
    case library
    case journal
    case stats
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .checkIn: "Home"
        case .library: "Library"
        case .journal: "Journal"
        case .stats: "Stats"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .checkIn: "house.fill"
        case .library: "books.vertical.fill"
        case .journal: "calendar"
        case .stats: "chart.bar.fill"
        case .settings: "gearshape.fill"
        }
    }

    @ViewBuilder
    var view: some View {
        switch self {
        case .checkIn: CheckInHomeView()
        case .library: LibraryView()
        case .journal: JournalView()
        case .stats: StatsView()
        case .settings: SettingsView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            DailyCheckIn.self,
            StreakRecord.self,
            Book.self,
            ReadingSession.self,
            Goal.self,
            UserSettings.self,
        ], inMemory: true)
}
