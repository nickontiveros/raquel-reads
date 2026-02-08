import Foundation
import SwiftData

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var kindleCookies: String?
    var kindleDeviceToken: String?
    var tlsClientApiUrl: String?
    var lastKindleSync: Date?
    var theme: AppTheme
    var streakFreezeActive: Bool
    var streakFreezeStart: Date?
    var streakFreezeEnd: Date?
    var lastExportedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        theme: AppTheme = .auto,
        streakFreezeActive: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.theme = theme
        self.streakFreezeActive = streakFreezeActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
