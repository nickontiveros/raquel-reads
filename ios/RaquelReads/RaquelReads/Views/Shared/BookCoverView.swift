import SwiftUI

struct BookCoverView: View {
    let coverUrl: String?
    var width: CGFloat = 80
    var height: CGFloat = 120

    var body: some View {
        if let coverUrl, let url = URL(string: coverUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    placeholder
                case .empty:
                    placeholder
                        .overlay {
                            ProgressView()
                        }
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.secondary.opacity(0.15))
            .frame(width: width, height: height)
            .overlay {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: width * 0.3))
                    .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    HStack(spacing: 16) {
        BookCoverView(coverUrl: nil)
        BookCoverView(coverUrl: "https://example.com/cover.jpg")
        BookCoverView(coverUrl: nil, width: 60, height: 90)
    }
}
