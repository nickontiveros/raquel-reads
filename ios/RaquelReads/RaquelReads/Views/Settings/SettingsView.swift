import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    @State private var streakFrozen = false
    @State private var showExportShare = false
    @State private var showImportPicker = false
    @State private var exportUrl: URL?
    @State private var importMessage: String?
    @State private var showImportResult = false

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
                Section {
                    Toggle(isOn: $streakFrozen) {
                        Label("Streak Freeze", systemImage: "snowflake")
                    }
                } header: {
                    Text("Streak")
                } footer: {
                    Text(streakFrozen
                         ? "Your streak is paused. It won't reset while frozen."
                         : "Freeze your streak during vacations or busy periods.")
                }

                // Kindle
                Section {
                    NavigationLink {
                        KindleSettingsPlaceholder()
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
                        exportData()
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showImportPicker = true
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
            .sheet(isPresented: $showExportShare) {
                if let url = exportUrl {
                    ShareSheet(items: [url])
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json]
            ) { result in
                handleImport(result)
            }
            .alert("Import Complete", isPresented: $showImportResult) {
                Button("OK") {}
            } message: {
                Text(importMessage ?? "")
            }
        }
    }

    private func exportData() {
        let service = DataExportService(modelContext: modelContext)
        do {
            let url = try service.exportToFile()
            exportUrl = url
            showExportShare = true
        } catch {
            importMessage = "Export failed: \(error.localizedDescription)"
            showImportResult = true
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let service = DataExportService(modelContext: modelContext)
            do {
                let importResult = try service.importFromFile(url: url)
                importMessage = importResult.summary
            } catch {
                importMessage = "Import failed: \(error.localizedDescription)"
            }
            showImportResult = true
        case .failure(let error):
            importMessage = "Could not open file: \(error.localizedDescription)"
            showImportResult = true
        }
    }
}

// MARK: - Share Sheet (UIKit bridge)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Kindle Settings Placeholder

struct KindleSettingsPlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Kindle Integration")
                .font(.headline)

            Text("Connect your Amazon Kindle account to automatically sync your reading progress. This requires a hosted TLS proxy server.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Coming in Phase 2")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
        .navigationTitle("Kindle")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [
            DailyCheckIn.self, Book.self, ReadingSession.self, Goal.self, UserSettings.self,
        ], inMemory: true)
}
