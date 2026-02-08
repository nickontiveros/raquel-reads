# Raquel Reads iOS App Plan

## Overview

Native iOS app for Raquel Reads — a personal reading tracker with Kindle integration, reading journals, statistics, and goal tracking. The iOS app will bring the full web experience to a native mobile platform with offline-first architecture and platform-native features.

---

## 1. Architecture & Tech Stack

### Recommended Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **UI Framework** | SwiftUI | Declarative, modern Apple standard, strong ecosystem |
| **Language** | Swift 6 | Latest concurrency features, type safety |
| **Local Database** | SwiftData (Core Data) | Apple-native, mirrors Dexie.js offline-first model |
| **Networking** | URLSession + async/await | Native, no third-party dependency needed |
| **Image Loading** | Nuke or AsyncImage | Cover image caching & loading |
| **Architecture** | MVVM | Natural fit with SwiftUI's data binding |
| **Minimum Target** | iOS 17+ | SwiftData support, modern SwiftUI features |

### Why Native Swift (Not React Native / Flutter)

- The web app is already client-side with IndexedDB — native SwiftData is the closest analog
- Platform-native feel for reading/journaling UX
- Better integration with iOS features (widgets, shortcuts, haptics)
- Kindle sync requires networking that benefits from native URLSession
- Small, focused app — no need for cross-platform overhead

---

## 2. Data Model (SwiftData)

Direct translation of the existing Dexie.js schema:

### Book
```
- id: UUID
- title: String
- author: String
- coverUrl: String?
- isbn: String?
- googleBooksId: String?
- kindleAsin: String?
- totalPages: Int?
- currentPage: Int
- percentComplete: Double
- status: BookStatus (reading | completed | paused | wantToRead)
- source: BookSource (manual | kindle)
- startedAt: Date?
- completedAt: Date?
- lastReadAt: Date?
- createdAt: Date
- updatedAt: Date
```

### ReadingSession
```
- id: UUID
- book: Book (relationship)
- date: Date
- pagesRead: Int
- startPage: Int?
- endPage: Int?
- durationMinutes: Int?
- notes: String?
- source: SessionSource (manual | kindle)
- createdAt: Date
- updatedAt: Date
```

### Goal
```
- id: UUID
- type: GoalType (dailyReading | booksPerMonth | booksPerYear | readingStreak | pagesPerDay)
- target: Int
- period: GoalPeriod (day | week | month | year)
- startDate: Date
- endDate: Date?
- active: Bool
- createdAt: Date
- updatedAt: Date
```

### UserSettings
```
- id: UUID
- kindleCookies: String?
- kindleDeviceToken: String?
- tlsClientApiUrl: String?
- lastKindleSync: Date?
- theme: AppTheme (light | dark | auto)
- defaultView: String?
- lastExportedAt: Date?
```

### SyncLog & KindleSnapshot
Same structure as web, stored in SwiftData.

---

## 3. App Screens (Tab-Based Navigation)

Mirrors the web app's 5 main pages:

### Tab 1: Dashboard (Home)
- Currently reading books (horizontal scroll)
- Reading streak display
- Today's reading summary (pages, time)
- Recent activity feed
- Quick action: Log reading session

### Tab 2: Library (Books)
- Segmented control: All / Reading / Completed / Want to Read
- Search bar with title/author filtering
- Grid or list view toggle
- Add book button (search Google Books or manual entry)
- Tap book → Book Detail screen

### Book Detail Screen (Push)
- Cover image, title, author
- Progress bar with page count
- Status picker (reading, completed, paused, want-to-read)
- Reading sessions list for this book
- Log reading session button
- Edit / Delete actions

### Tab 3: Journal
- Calendar view (month grid) with dots on reading days
- Tap a day → list of reading sessions for that date
- Add session from any date
- Streak indicators

### Tab 4: Statistics
- Total books read, pages read, current streak, longest streak
- Active goals with progress bars
- Monthly reading chart
- Reading pace trends
- Add/edit goals

### Tab 5: Settings
- Kindle credentials management
- Sync button with last sync timestamp
- Export/Import data (JSON, same format as web)
- Theme selection
- About / version info

---

## 4. Feature Parity with Web App

| Web Feature | iOS Equivalent | Priority |
|-------------|---------------|----------|
| Book CRUD | SwiftData CRUD | P0 |
| Google Books search | API call from iOS | P0 |
| Reading session logging | Native form with date picker | P0 |
| Reading calendar/journal | Custom calendar view | P0 |
| Statistics dashboard | Charts (Swift Charts) | P0 |
| Goal tracking | Goal cards with progress | P0 |
| Kindle sync | API call to hosted tls-client-api | P1 |
| Data export/import (JSON) | Share sheet / Files app integration | P1 |
| Dark mode | Native iOS dark mode support | P0 |
| Search/filter books | SearchableModifier | P0 |

---

## 5. iOS-Specific Enhancements

Features that go beyond the web app, leveraging iOS capabilities:

### Phase 1 (Launch)
- **Haptic feedback** on logging sessions, completing books
- **Pull-to-refresh** on Kindle sync
- **Swipe actions** on book list (mark complete, delete)
- **Share sheet** for sharing reading stats as images

### Phase 2 (Post-Launch)
- **Home Screen Widgets** — current book progress, streak counter, daily reading goal
- **Live Activities** — active reading session timer on lock screen
- **App Shortcuts / Siri** — "Log my reading" voice command
- **App Intents** — expose actions to Shortcuts app
- **Barcode scanner** — scan ISBN to add books
- **Notifications** — daily reading reminders, streak-at-risk alerts
- **iCloud sync** — sync data across devices via CloudKit

---

## 6. Kindle Sync on iOS

The web app uses a Docker-hosted `tls-client-api` to bypass Amazon's TLS fingerprinting. On iOS:

### Recommended Approach
- **Keep the hosted tls-client-api server** — the iOS app calls it the same way the web API route does
- The `/api/kindle/sync` logic moves into a Swift `KindleSyncService`
- User enters Amazon cookies + device token in Settings (same as web)
- The service calls the hosted TLS proxy, which communicates with Amazon
- Delta detection and snapshot comparison logic ported to Swift

### Architecture
```
iOS App → KindleSyncService (Swift)
       ↓
  tls-client-api (hosted server, e.g. Fly.io)
       ↓
  Amazon Kindle servers
```

No changes needed to the TLS proxy infrastructure.

---

## 7. Data Sync Between Web & iOS

Since the web app stores everything in IndexedDB (browser-local), a sync strategy is needed:

### Option A: JSON Export/Import (Simple, Phase 1)
- Export from web → JSON file → import on iOS (and vice versa)
- Uses the existing export format: `{ version, exportedAt, books[], readingSessions[], goals[] }`
- Manual process via share sheet or AirDrop

### Option B: iCloud Sync (Phase 2)
- Store SwiftData in CloudKit-backed container
- Only syncs across iOS/macOS devices (not web)
- Automatic, seamless

### Option C: Backend API with Auth (Phase 3, if needed)
- Add a backend service (e.g., Supabase, Firebase, or custom API)
- Both web and iOS authenticate and sync to the same backend
- Full cross-platform sync
- Requires adding authentication to both platforms

**Recommendation:** Start with Option A, move to Option B for Apple ecosystem sync. Only build Option C if cross-platform real-time sync becomes a requirement.

---

## 8. Project Structure

```
RaquelReads/
├── RaquelReadsApp.swift          # App entry point
├── Models/
│   ├── Book.swift                # SwiftData model
│   ├── ReadingSession.swift
│   ├── Goal.swift
│   ├── UserSettings.swift
│   ├── SyncLog.swift
│   ├── KindleSnapshot.swift
│   └── Enums.swift               # BookStatus, GoalType, etc.
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   ├── CurrentlyReadingRow.swift
│   │   └── RecentActivityView.swift
│   ├── Library/
│   │   ├── LibraryView.swift
│   │   ├── BookCardView.swift
│   │   ├── BookDetailView.swift
│   │   └── AddBookView.swift
│   ├── Journal/
│   │   ├── JournalView.swift
│   │   ├── ReadingCalendarView.swift
│   │   └── DayDetailView.swift
│   ├── Stats/
│   │   ├── StatsView.swift
│   │   ├── GoalCardView.swift
│   │   └── ReadingChartView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── KindleSettingsView.swift
│   └── Shared/
│       ├── LogReadingView.swift
│       ├── AddGoalView.swift
│       └── BookCoverView.swift
├── ViewModels/
│   ├── DashboardViewModel.swift
│   ├── LibraryViewModel.swift
│   ├── JournalViewModel.swift
│   ├── StatsViewModel.swift
│   └── SettingsViewModel.swift
├── Services/
│   ├── BookService.swift
│   ├── ReadingSessionService.swift
│   ├── GoalService.swift
│   ├── StatsService.swift
│   ├── KindleSyncService.swift
│   ├── GoogleBooksService.swift
│   └── DataExportService.swift
├── Utilities/
│   ├── DateFormatters.swift
│   └── Extensions.swift
├── Widgets/
│   ├── ReadingStreakWidget.swift
│   └── CurrentBookWidget.swift
└── Resources/
    └── Assets.xcassets
```

---

## 9. Implementation Phases

### Phase 1: Core App (MVP)
**Goal:** Feature parity with the web app's core functionality.

1. **Project setup** — Xcode project, SwiftData schema, tab navigation
2. **Data models** — Port all 6 tables to SwiftData models
3. **Library screen** — Book list with filtering, search, add book (manual)
4. **Google Books integration** — Search and add books from API
5. **Book detail screen** — View/edit book, progress tracking
6. **Reading session logging** — Log pages read with date picker
7. **Dashboard** — Currently reading, streak, recent activity
8. **Journal** — Calendar view with reading day indicators
9. **Statistics** — Reading stats, charts (Swift Charts)
10. **Goal tracking** — Create goals, display progress
11. **Settings** — Theme, data export/import
12. **Dark mode** — System-native appearance support

### Phase 2: Kindle & Platform Features
1. **Kindle sync** — Port sync logic, connect to tls-client-api
2. **Home screen widgets** — Streak, current book progress
3. **Barcode scanning** — ISBN scanner to add physical books
4. **Reading reminders** — Local notifications
5. **Share reading stats** — Generate shareable images

### Phase 3: Advanced Features
1. **iCloud sync** — CloudKit-backed SwiftData for multi-device
2. **Live Activities** — Reading session timer on lock screen
3. **Siri & Shortcuts** — App Intents for voice commands
4. **Apple Watch companion** — Quick log, streak glance
5. **iPad layout** — Multi-column adaptive layout

---

## 10. Key Technical Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Persistence | SwiftData | Mirrors the offline-first IndexedDB approach |
| No backend required | Yes (Phase 1-2) | Same local-storage model as web |
| Kindle sync server | Reuse existing tls-client-api | No new infrastructure needed |
| Charts | Swift Charts | Native framework, no dependencies |
| Image caching | Nuke | Mature, performant, SwiftUI support |
| Min iOS version | 17 | SwiftData, modern SwiftUI, Swift Charts |
| Package manager | Swift Package Manager | Standard for Swift projects |

---

## 11. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Kindle API instability | Sync breaks if Amazon changes APIs | Graceful degradation; sync is P1, core app works without it |
| tls-client-api hosting | Requires running a server for Kindle sync | Document self-hosting options; make URL configurable |
| No web↔iOS sync initially | Users have data in both places | JSON export/import bridges the gap in Phase 1 |
| SwiftData maturity | Potential bugs in newer framework | Fallback to Core Data if critical issues found |
| App Store review for Kindle integration | Amazon credential storage may raise concerns | Store in Keychain; clearly document user consent |

---

## 12. Estimated Scope

| Phase | Screens | Services | Effort Level |
|-------|---------|----------|-------------|
| Phase 1 (MVP) | 8 screens | 5 services | Medium-Large |
| Phase 2 (Kindle + Widgets) | +3 screens | +2 services | Medium |
| Phase 3 (Advanced) | +2 screens | +1 service | Medium |

---

## Summary

The iOS app is a natural extension of Raquel Reads. The web app's offline-first, client-side architecture maps cleanly to SwiftData, and the existing Kindle sync infrastructure can be reused without modification. Phase 1 delivers a fully functional reading tracker; Phase 2 adds Kindle sync and iOS-native features; Phase 3 brings multi-device sync and advanced platform integration.
