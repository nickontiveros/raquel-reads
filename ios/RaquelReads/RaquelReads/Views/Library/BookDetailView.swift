import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let book: Book

    @State private var bookService: BookService?
    @State private var sessions: [ReadingSession] = []
    @State private var showLogReading = false
    @State private var showDeleteConfirm = false
    @State private var showEditStatus = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Cover + Title
                headerSection

                // Progress
                progressSection

                // Status
                statusSection

                // Actions
                actionButtons

                // Reading Sessions
                sessionsSection
            }
            .padding()
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog("Delete Book", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                bookService?.delete(book)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \"\(book.title)\"? This will also delete all reading sessions for this book.")
        }
        .sheet(isPresented: $showLogReading) {
            LogReadingSheet(book: book)
                .onDisappear { refreshSessions() }
        }
        .onAppear {
            if bookService == nil {
                bookService = BookService(modelContext: modelContext)
            }
            refreshSessions()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 16) {
            BookCoverView(coverUrl: book.coverUrl, width: 100, height: 150)

            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(3)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let pages = book.totalPages {
                    Label("\(pages) pages", systemImage: "doc.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let isbn = book.isbn {
                    Label(isbn, systemImage: "barcode")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.headline)
                Spacer()
                Text("\(Int(book.percentComplete))%")
                    .font(.headline)
                    .foregroundStyle(.accentColor)
            }

            ProgressView(value: book.percentComplete, total: 100)
                .tint(.accentColor)

            if let totalPages = book.totalPages {
                HStack {
                    Text("Page \(book.currentPage)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("of \(totalPages)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 8) {
                ForEach(BookStatus.allCases) { status in
                    Button {
                        bookService?.updateStatus(book, to: status)
                        HapticManager.tap()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: status.icon)
                                .font(.caption)
                            Text(status.label)
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            book.status == status
                                ? Color.accentColor
                                : Color.secondary.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .foregroundStyle(book.status == status ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Dates
            VStack(alignment: .leading, spacing: 4) {
                if let started = book.startedAt {
                    Label("Started \(started.shortDayString)", systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let completed = book.completedAt {
                    Label("Completed \(completed.shortDayString)", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                if let lastRead = book.lastReadAt {
                    Label("Last read \(lastRead.shortDayString)", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showLogReading = true
            } label: {
                Label("Log Reading", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    // MARK: - Sessions

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reading Sessions")
                    .font(.headline)
                Spacer()
                Text("\(sessions.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if sessions.isEmpty {
                Text("No reading sessions yet. Tap \"Log Reading\" to record your progress.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(sessions) { session in
                    SessionRow(session: session)
                }
            }
        }
    }

    private func refreshSessions() {
        let sessionService = ReadingSessionService(modelContext: modelContext)
        sessions = sessionService.fetchByBook(book)
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: ReadingSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.date.friendlyDayString)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    if session.pagesRead > 0 {
                        Label("\(session.pagesRead) pages", systemImage: "doc.text")
                    }
                    if let duration = session.durationMinutes, duration > 0 {
                        Label("\(duration) min", systemImage: "clock")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let notes = session.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if let start = session.startPage, let end = session.endPage {
                Text("p.\(start)–\(end)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        BookDetailView(
            book: Book(
                title: "Dune",
                author: "Frank Herbert",
                totalPages: 412,
                currentPage: 156,
                percentComplete: 37.8,
                status: .reading
            )
        )
    }
    .modelContainer(for: [Book.self, ReadingSession.self], inMemory: true)
}
