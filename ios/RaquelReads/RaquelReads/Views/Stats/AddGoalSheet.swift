import SwiftUI
import SwiftData

struct AddGoalSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: GoalType = .booksPerMonth
    @State private var target = ""
    @State private var goalService: GoalService?

    private var isValid: Bool {
        guard let value = Int(target), value > 0 else { return false }
        return true
    }

    private var period: GoalPeriod {
        switch selectedType {
        case .dailyReading: .day
        case .booksPerMonth: .month
        case .booksPerYear: .year
        case .readingStreak: .day
        case .pagesPerDay: .day
        }
    }

    private var targetLabel: String {
        switch selectedType {
        case .dailyReading: "Minutes per day"
        case .booksPerMonth: "Books per month"
        case .booksPerYear: "Books per year"
        case .readingStreak: "Consecutive days"
        case .pagesPerDay: "Pages per day"
        }
    }

    private var previewText: String {
        guard let value = Int(target), value > 0 else { return "" }
        switch selectedType {
        case .dailyReading:
            return "Read for \(value.pluralized("minute")) every day"
        case .booksPerMonth:
            return "Finish \(value.pluralized("book")) each month"
        case .booksPerYear:
            return "Finish \(value.pluralized("book")) this year"
        case .readingStreak:
            return "Build a \(value)-day reading streak"
        case .pagesPerDay:
            return "Read \(value.pluralized("page")) every day"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Goal type picker
                Section("Goal Type") {
                    ForEach(GoalType.allCases) { type in
                        Button {
                            selectedType = type
                            HapticManager.tap()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: type.icon)
                                    .font(.title3)
                                    .foregroundStyle(.accentColor)
                                    .frame(width: 28)

                                Text(type.label)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if selectedType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.accentColor)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Target
                Section {
                    TextField(targetLabel, text: $target)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Target")
                } footer: {
                    if !previewText.isEmpty {
                        Text(previewText)
                            .foregroundStyle(.accentColor)
                    }
                }

                // Save
                Section {
                    Button(action: saveGoal) {
                        Label("Create Goal", systemImage: "target")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if goalService == nil {
                    goalService = GoalService(modelContext: modelContext)
                }
            }
        }
    }

    private func saveGoal() {
        guard let value = Int(target), value > 0 else { return }

        _ = goalService?.addGoal(type: selectedType, target: value, period: period)
        HapticManager.checkInSuccess()
        dismiss()
    }
}

#Preview {
    AddGoalSheet()
        .modelContainer(for: Goal.self, inMemory: true)
}
