import SwiftUI
import SwiftData

struct LogReadingSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Pre-selected book (when opened from BookDetailView)
    var book: Book?

    /// Pre-selected check-in (when opened from CheckInHomeView)
    var checkIn: DailyCheckIn?

    @State private var selectedBook: Book?
    @State private var pagesRead = ""
    @State private var startPage = ""
    @State private var endPage = ""
    @State private var durationMinutes = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var usePageRange = false
    @State private var showBookPicker = false

    @Query(
        filter: #Predicate<Book> { $0.status == .reading },
        sort: \Book.updatedAt, order: .reverse
    )
    private var readingBooks: [Book]

    private var isValid: Bool {
        if usePageRange {
            guard let start = Int(startPage), let end = Int(endPage), end >= start else {
                return false
            }
            return true
        } else {
            guard let pages = Int(pagesRead), pages > 0 else {
                return false
            }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Book selection
                Section("Book") {
                    if let selected = selectedBook {
                        HStack(spacing: 12) {
                            BookCoverView(coverUrl: selected.coverUrl, width: 36, height: 52)

                            VStack(alignment: .leading) {
                                Text(selected.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                Text(selected.author)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            if book == nil {
                                Button("Change") {
                                    showBookPicker = true
                                }
                                .font(.caption)
                            }
                        }
                    } else {
                        Button {
                            showBookPicker = true
                        } label: {
                            Label("Select a book (optional)", systemImage: "book.closed")
                        }
                    }
                }

                // Pages
                Section("Pages") {
                    Toggle("Use page range", isOn: $usePageRange)

                    if usePageRange {
                        HStack {
                            TextField("Start page", text: $startPage)
                                .keyboardType(.numberPad)
                            Text("to")
                                .foregroundStyle(.secondary)
                            TextField("End page", text: $endPage)
                                .keyboardType(.numberPad)
                        }
                    } else {
                        TextField("Pages read", text: $pagesRead)
                            .keyboardType(.numberPad)
                    }
                }

                // Duration & Notes
                Section("Details (optional)") {
                    HStack {
                        TextField("Duration", text: $durationMinutes)
                            .keyboardType(.numberPad)
                        Text("minutes")
                            .foregroundStyle(.secondary)
                    }

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Date
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                // Save
                Section {
                    Button(action: saveSession) {
                        Label("Save Session", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Log Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showBookPicker) {
                BookPickerSheet(books: readingBooks, selection: $selectedBook)
            }
            .onAppear {
                if let book {
                    selectedBook = book
                }
                // Pre-fill start page from current book progress
                if let book, book.currentPage > 0 {
                    startPage = "\(book.currentPage)"
                    usePageRange = true
                }
            }
        }
    }

    private func saveSession() {
        let sessionService = ReadingSessionService(modelContext: modelContext)

        let pages: Int
        let start: Int?
        let end: Int?

        if usePageRange {
            start = Int(startPage)
            end = Int(endPage)
            pages = (end ?? 0) - (start ?? 0)
        } else {
            pages = Int(pagesRead) ?? 0
            start = nil
            end = nil
        }

        let duration = Int(durationMinutes)
        let noteText = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)

        _ = sessionService.logSession(
            book: selectedBook,
            checkIn: checkIn,
            date: date,
            pagesRead: pages,
            startPage: start,
            endPage: end,
            durationMinutes: duration,
            notes: noteText
        )

        HapticManager.checkInSuccess()
        dismiss()
    }
}

// MARK: - Book Picker

struct BookPickerSheet: View {
    let books: [Book]
    @Binding var selection: Book?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(books) { book in
                Button {
                    selection = book
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        BookCoverView(coverUrl: book.coverUrl, width: 36, height: 52)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            Text(book.author)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        if selection?.id == book.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.accentColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Select Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    LogReadingSheet()
        .modelContainer(for: [Book.self, ReadingSession.self, DailyCheckIn.self], inMemory: true)
}
