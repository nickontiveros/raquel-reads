import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()

    var body: some View {
        NavigationStack {
            List {
                // Reading Reminders
                Section {
                    Toggle("Daily Reading Reminder", isOn: $reminderEnabled)

                    if reminderEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("A gentle nudge to help you keep your reading habit going.")
                }

                // Streak
                Section("Streak") {
                    Button {
                        // TODO: Implement streak freeze
                    } label: {
                        Label("Streak Freeze", systemImage: "snowflake")
                    }
                }

                // Kindle
                Section {
                    Button {
                        // TODO: Open Kindle settings
                    } label: {
                        Label("Kindle Integration", systemImage: "arrow.triangle.2.circlepath")
                    }
                } header: {
                    Text("Sync")
                } footer: {
                    Text("Connect your Kindle account to automatically track reading progress.")
                }

                // Data
                Section("Data") {
                    Button {
                        // TODO: Export
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        // TODO: Import
                    } label: {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
