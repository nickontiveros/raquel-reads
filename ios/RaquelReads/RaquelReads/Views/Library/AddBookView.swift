import SwiftUI
import SwiftData

struct AddBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: AddBookTab = .search
    @State private var bookService: BookService?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Add Method", selection: $selectedTab) {
                    Text("Search").tag(AddBookTab.search)
                    Text("Manual").tag(AddBookTab.manual)
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case .search:
                    SearchBookTab(bookService: bookService) { dismiss() }
                case .manual:
                    ManualBookTab(bookService: bookService) { dismiss() }
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if bookService == nil {
                    bookService = BookService(modelContext: modelContext)
                }
            }
        }
    }
}

private enum AddBookTab {
    case search, manual
}

// MARK: - Search Tab

private struct SearchBookTab: View {
    let bookService: BookService?
    let onComplete: () -> Void

    @State private var query = ""
    @State private var results: [GoogleBookResult] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var errorMessage: String?
    @State private var selectedResult: GoogleBookResult?
    @State private var selectedStatus: BookStatus = .wantToRead

    private let googleBooks = GoogleBooksService()

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                TextField("Search by title or author...", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.search)
                    .onSubmit { search() }

                if isSearching {
                    ProgressView()
                        .padding(.leading, 4)
                } else {
                    Button("Search") { search() }
                        .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            if let error = errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .padding()
            }

            // Results
            if results.isEmpty && hasSearched {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search term.")
                )
            } else {
                List(results) { result in
                    SearchResultRow(result: result) {
                        selectedResult = result
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(item: $selectedResult) { result in
            SearchResultPreview(
                result: result,
                selectedStatus: $selectedStatus,
                onAdd: {
                    addFromSearch(result)
                }
            )
            .presentationDetents([.medium])
        }
    }

    private func search() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        errorMessage = nil
        hasSearched = true

        Task {
            do {
                let searchResults = try await googleBooks.search(query: query)
                await MainActor.run {
                    results = searchResults
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSearching = false
                }
            }
        }
    }

    private func addFromSearch(_ result: GoogleBookResult) {
        _ = bookService?.addBook(
            title: result.title,
            author: result.author,
            coverUrl: result.coverUrl,
            isbn: result.isbn,
            googleBooksId: result.id,
            totalPages: result.pageCount,
            status: selectedStatus
        )
        HapticManager.checkInSuccess()
        onComplete()
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let result: GoogleBookResult
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                BookCoverView(coverUrl: result.coverUrl, width: 44, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(2)

                    Text(result.author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let pages = result.pageCount {
                            Text("\(pages) pages")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        if result.isbn != nil {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Search Result Preview

private struct SearchResultPreview: View {
    let result: GoogleBookResult
    @Binding var selectedStatus: BookStatus
    let onAdd: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    BookCoverView(coverUrl: result.coverUrl, width: 80, height: 120)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(result.title)
                            .font(.headline)
                            .lineLimit(3)

                        Text(result.author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let pages = result.pageCount {
                            Label("\(pages) pages", systemImage: "doc.text")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }

                if let description = result.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }

                // Status picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add as:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Picker("Status", selection: $selectedStatus) {
                        ForEach(BookStatus.allCases) { status in
                            Text(status.label).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Button(action: onAdd) {
                    Label("Add to Library", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Manual Tab

private struct ManualBookTab: View {
    let bookService: BookService?
    let onComplete: () -> Void

    @State private var title = ""
    @State private var author = ""
    @State private var totalPages = ""
    @State private var isbn = ""
    @State private var status: BookStatus = .wantToRead

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !author.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section("Book Details") {
                TextField("Title", text: $title)
                TextField("Author", text: $author)
                TextField("Total Pages (optional)", text: $totalPages)
                    .keyboardType(.numberPad)
                TextField("ISBN (optional)", text: $isbn)
                    .keyboardType(.numberPad)
            }

            Section("Status") {
                Picker("Status", selection: $status) {
                    ForEach(BookStatus.allCases) { s in
                        Label(s.label, systemImage: s.icon).tag(s)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section {
                Button(action: addManualBook) {
                    Label("Add to Library", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
    }

    private func addManualBook() {
        let pages = Int(totalPages)
        let isbnValue = isbn.isEmpty ? nil : isbn

        _ = bookService?.addBook(
            title: title.trimmingCharacters(in: .whitespaces),
            author: author.trimmingCharacters(in: .whitespaces),
            isbn: isbnValue,
            totalPages: pages,
            status: status
        )
        HapticManager.checkInSuccess()
        onComplete()
    }
}

#Preview {
    AddBookView()
        .modelContainer(for: Book.self, inMemory: true)
}
