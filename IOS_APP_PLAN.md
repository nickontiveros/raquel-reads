# Raquel Reads iOS App Plan

## Overview

Native iOS app for Raquel Reads — a reading tracker that **celebrates the habit of reading**, not just the metrics around it. The core interaction is answering one simple question: *"Did I read today?"* Everything else — books, pages, Kindle sync, statistics — is secondary and optional.

### Design Philosophy

Most reading apps (Goodreads, Bookly, Libby) are built around *books* — cataloging, reviewing, tracking progress through specific titles. Raquel Reads Mobile is built around *the reader* — did you make time for reading today? That's it. That's the win.

This is inspired by patterns from:
- **Finch** (self-care app) — radical guilt-free design, confetti celebrations, streak repair, no punishment for missed days
- **Streaks** (habit tracker) — one-action home screen, the check-in IS the app
- **Headspace** — compassionate tone, optional streak visibility, "pick up where you left off"

The key insight: for people building a reading habit, "I read for 10 minutes on the bus" matters just as much as "I finished Chapter 12 of War and Peace." The app should celebrate both equally.

---

## 1. The Core Loop: Daily Check-In

### What you see when you open the app

The home screen has one dominant element: a large, tappable button.

```
┌─────────────────────────────────┐
│                                 │
│     🔥 12-day streak            │
│                                 │
│    ┌───────────────────────┐    │
│    │                       │    │
│    │    I read today ✓     │    │
│    │                       │    │
│    └───────────────────────┘    │
│                                 │
│    "You've read 4 days this     │
│     week — your best yet!"     │
│                                 │
│  ┌─────────┐  ┌─────────┐      │
│  │ What I  │  │ How far │      │
│  │  read   │  │ I got   │      │
│  └─────────┘  └─────────┘      │
│       optional details          │
│                                 │
│  ── Recent ──────────────       │
│  📖 Currently reading...        │
│                                 │
└─────────────────────────────────┘
  🏠    📚    📅    📊    ⚙️
```

**The button is the entire point.** Tap it, and:
1. Confetti animation fills the screen
2. Haptic feedback (a satisfying "success" tap)
3. Streak counter animates upward
4. An encouraging message appears ("3 days in a row!", "You showed up for yourself today")
5. The button transforms into a checkmark with a warm glow for the rest of the day

**Below the button**, two optional detail cards invite (never require) the user to add context:
- "What I read" — attach a book from your library
- "How far I got" — log pages or percentage

These are clearly secondary. The check-in is already complete.

### The Catch-Up Flow (Missed Days)

When a user opens the app after missing one or more days, the home screen shows a **catch-up carousel** before the daily button:

```
┌─────────────────────────────────┐
│                                 │
│  "Welcome back! Let's catch up" │
│                                 │
│   ← Swipe →                    │
│  ┌─────────────────────────┐    │
│  │   Wednesday, Feb 4      │    │
│  │                         │    │
│  │   Did you read?         │    │
│  │                         │    │
│  │   ← No    Yes →         │    │
│  └─────────────────────────┘    │
│                                 │
│  ● ○ ○  (3 days to catch up)   │
│                                 │
└─────────────────────────────────┘
```

- **Swipe right = Yes**, I read that day (card flies off right with a mini celebration)
- **Swipe left = No**, I didn't (card flies off left — no judgment, no negative feedback, just moves on)
- A **"Skip catch-up"** link at the bottom lets the user dismiss entirely
- After catching up, today's check-in button appears as normal
- Caught-up "yes" days are **retroactively added** to streak calculations and the journal calendar

**Tone is critical here.** The catch-up is framed as "let's fill in your story" not "you missed 3 days." The language is always warm:
- "Welcome back! Your book missed you."
- "Let's see how your week went."
- "No pressure — just checking in."

### Streak Design

Inspired by Finch's guilt-free model, not Duolingo's punitive one:

- **Streak counts consecutive days with a check-in** (yes or no — opening the app and engaging counts)
- **Streak repair:** If a user retroactively marks a missed day as "yes" during catch-up, the streak is restored
- **Streak freeze:** Users can pre-emptively "pause" their streak for vacations, busy weeks, etc.
- **No shame language.** A broken streak says "Ready to start a new streak?" not "You lost your 12-day streak!"
- **Milestone celebrations:** Special animations at 7, 14, 30, 50, 100 days
- **Best streak is always visible** — even if the current streak resets, the record stands as encouragement

---

## 2. Celebration & Delight

The app should feel like a friend cheering you on, not a spreadsheet tracking your output.

### Confetti & Animations
- **Daily check-in:** Full-screen confetti burst + haptic + streak counter animates
- **Streak milestones (7, 14, 30, 50, 100):** Special themed animations (e.g., books flying, fireworks, a little reading character doing a dance)
- **Completing a book:** Unique celebration — the book cover animates onto a "finished" shelf with sparkles
- **Catch-up "yes" swipe:** Mini confetti puff on the card as it flies away

### Encouraging Messages
Rotating, contextual messages that appear after check-in:
- "You showed up for yourself today."
- "3 days in a row — that's a habit forming!"
- "Reading is self-care. You earned this."
- "Every page counts, even just one."
- "Your future self is thanking you right now."
- "That's your longest streak ever! You're on fire."

### What We DON'T Do
- No guilt for missed days — ever
- No "you're falling behind" notifications
- No comparison to other users
- No "you only read 5 pages today" type messaging
- Reminders are opt-in and gentle ("Your book is waiting for you" not "You haven't read today!")

---

## 3. Information Hierarchy

The app has a clear priority order. Everything is available, but the UI guides attention:

### Priority 1: Did I read today? (Home screen)
The check-in button. Zero friction. One tap.

### Priority 2: My streak & reading calendar (Home + Journal tab)
Visual proof that you're showing up. The calendar fills in with colored dots. The streak counter grows.

### Priority 3: What I'm reading (Library tab)
Your bookshelf. Add books, see covers, browse. But you never *need* to be here to use the app.

### Priority 4: How far I've gotten (Book detail)
Page numbers, percentages, Kindle sync progress. Available for users who want it, invisible to those who don't.

### Priority 5: Deep statistics (Stats tab)
Charts, trends, pace calculations. For the data-curious, not required.

---

## 4. Architecture & Tech Stack

### Recommended Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **UI Framework** | SwiftUI | Declarative, modern Apple standard, strong ecosystem |
| **Language** | Swift 6 | Latest concurrency features, type safety |
| **Local Database** | SwiftData (Core Data) | Apple-native, mirrors Dexie.js offline-first model |
| **Networking** | URLSession + async/await | Native, no third-party dependency needed |
| **Image Loading** | Nuke or AsyncImage | Cover image caching & loading |
| **Animations** | SwiftUI + Lottie | Native for transitions, Lottie for confetti/celebrations |
| **Architecture** | MVVM | Natural fit with SwiftUI's data binding |
| **Minimum Target** | iOS 17+ | SwiftData support, modern SwiftUI features |

### Why Native Swift (Not React Native / Flutter)

- Haptic engine access for satisfying check-in feedback
- Native animation performance for confetti/celebrations
- Platform-native feel for the daily ritual
- Widget and Live Activity support
- The web app's offline-first IndexedDB model maps cleanly to SwiftData
- Small, focused app — no need for cross-platform overhead

---

## 5. Data Model (SwiftData)

Extends the web app's schema with a new `DailyCheckIn` model as the primary entity:

### DailyCheckIn (NEW — primary model)
```
- id: UUID
- date: Date (day only, no time)
- didRead: Bool
- source: CheckInSource (manual | catchUp | automatic)
- celebrationShown: Bool
- createdAt: Date
```

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
- checkIn: DailyCheckIn? (relationship — optional link to check-in)
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

### StreakRecord (NEW)
```
- id: UUID
- startDate: Date
- endDate: Date?
- length: Int
- isCurrent: Bool
- isBest: Bool
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
- streakFreezeActive: Bool
- streakFreezeStart: Date?
- streakFreezeEnd: Date?
- lastExportedAt: Date?
```

### SyncLog & KindleSnapshot
Same structure as web, stored in SwiftData.

---

## 6. App Screens

### Tab 1: Home (Check-In)
**The heart of the app.** See Section 1 for the full check-in flow.
- Daily check-in button (primary)
- Catch-up carousel (when days are missed)
- Streak counter with milestone badge
- Encouraging message
- Optional detail cards: "What I read" / "How far I got"
- Currently reading books (horizontal scroll, below the fold)
- Recent activity feed (compact)

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
- Calendar view (month grid) with filled dots on reading days, empty dots on non-reading days
- Tap a day → details for that day (check-in status, sessions, books read)
- Visual streak highlighting (consecutive reading days connected)
- Current streak and best streak displayed
- Can retroactively mark days from the calendar

### Tab 4: Statistics
- Streak stats front and center (current, best, total reading days)
- Active goals with progress bars
- Books completed this month/year
- Pages read trends (Swift Charts)
- Weekly reading pattern (which days you tend to read)
- Add/edit goals

### Tab 5: Settings
- **Reading reminders** — opt-in, gentle tone, customizable time
- **Streak freeze** — pause/resume
- Kindle credentials management
- Sync button with last sync timestamp
- Export/Import data (JSON, same format as web)
- Theme selection
- About / version info

---

## 7. Kindle Sync (Background, Secondary)

Kindle sync runs **in the background** and feeds into the system passively. It should never interrupt the check-in flow.

### How it integrates with check-ins
- If Kindle data shows reading activity on a given day, the app can **auto-fill** the check-in for that day
- The user still sees the celebration when they open the app ("Looks like you were reading on your Kindle today!")
- Kindle progress updates book percentages and page counts silently
- New Kindle books are added to the library automatically

### Architecture (unchanged from web)
```
iOS App → KindleSyncService (Swift)
       ↓
  tls-client-api (hosted server, e.g. Fly.io)
       ↓
  Amazon Kindle servers
```

No changes needed to the TLS proxy infrastructure.

---

## 8. iOS-Specific Enhancements

### Phase 1 (Launch)
- **Confetti & celebration animations** (Lottie) on check-in and milestones
- **Haptic feedback** — satisfying tap on check-in, gentle buzz on streak milestones
- **Swipe gestures** for catch-up flow (left = no, right = yes)
- **Pull-to-refresh** on Kindle sync
- **Swipe actions** on book list (mark complete, delete)

### Phase 2 (Post-Launch)
- **Home Screen Widget** — streak counter + "I read today" button directly on home screen
- **Lock Screen Widget** — current streak at a glance
- **Live Activities** — active reading session timer on Dynamic Island
- **App Shortcuts / Siri** — "Hey Siri, I read today" to check in without opening the app
- **Barcode scanner** — scan ISBN to add physical books
- **Gentle notifications** — opt-in daily reminders with warm copy
- **Share streak** — generate shareable images of reading streaks and milestones

### Phase 3 (Advanced)
- **iCloud sync** — CloudKit-backed SwiftData for multi-device
- **Apple Watch** — check-in complication, streak glance, tap to mark "I read"
- **iPad layout** — multi-column adaptive layout
- **Streak-at-risk notification** — gentle evening nudge ("Still time to keep your streak going!")

---

## 9. Data Sync Between Web & iOS

Since the web app stores everything in IndexedDB (browser-local), a sync strategy is needed:

### Option A: JSON Export/Import (Simple, Phase 1)
- Export from web → JSON file → import on iOS (and vice versa)
- Uses the existing export format: `{ version, exportedAt, books[], readingSessions[], goals[] }`
- iOS adds `dailyCheckIns[]` to the export format
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

## 10. Project Structure

```
RaquelReads/
├── RaquelReadsApp.swift              # App entry point
├── Models/
│   ├── DailyCheckIn.swift            # NEW — primary model
│   ├── StreakRecord.swift             # NEW — streak tracking
│   ├── Book.swift                    # SwiftData model
│   ├── ReadingSession.swift
│   ├── Goal.swift
│   ├── UserSettings.swift
│   ├── SyncLog.swift
│   ├── KindleSnapshot.swift
│   └── Enums.swift                   # BookStatus, GoalType, etc.
├── Views/
│   ├── CheckIn/                      # NEW — the core experience
│   │   ├── CheckInHomeView.swift     # Main home screen
│   │   ├── CheckInButton.swift       # The big "I read today" button
│   │   ├── CatchUpCarousel.swift     # Missed days swipe flow
│   │   ├── StreakCounterView.swift    # Animated streak display
│   │   ├── CelebrationOverlay.swift  # Confetti & milestone animations
│   │   └── EncouragingMessage.swift  # Rotating encouragement
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
│   ├── CheckInViewModel.swift        # NEW — check-in + streak logic
│   ├── CatchUpViewModel.swift        # NEW — missed days flow
│   ├── LibraryViewModel.swift
│   ├── JournalViewModel.swift
│   ├── StatsViewModel.swift
│   └── SettingsViewModel.swift
├── Services/
│   ├── CheckInService.swift          # NEW — daily check-in CRUD
│   ├── StreakService.swift            # NEW — streak calculations
│   ├── CelebrationService.swift      # NEW — animation triggers
│   ├── BookService.swift
│   ├── ReadingSessionService.swift
│   ├── GoalService.swift
│   ├── StatsService.swift
│   ├── KindleSyncService.swift
│   ├── GoogleBooksService.swift
│   └── DataExportService.swift
├── Animations/
│   ├── Confetti.json                 # Lottie animation files
│   ├── StreakMilestone7.json
│   ├── StreakMilestone30.json
│   ├── StreakMilestone100.json
│   └── BookComplete.json
├── Utilities/
│   ├── DateFormatters.swift
│   ├── HapticManager.swift           # NEW — haptic feedback patterns
│   └── Extensions.swift
├── Widgets/
│   ├── StreakWidget.swift             # Home/Lock screen streak
│   └── CheckInWidget.swift           # "I read today" widget button
└── Resources/
    └── Assets.xcassets
```

---

## 11. Implementation Phases

### Phase 1: Check-In Core (MVP)
**Goal:** The daily check-in loop works perfectly and feels delightful.

1. **Project setup** — Xcode project, SwiftData schema, tab navigation
2. **DailyCheckIn + StreakRecord models** — the new primary data models
3. **Check-in home screen** — the big button, streak counter, encouraging messages
4. **Confetti & celebration animations** — Lottie integration, haptic feedback
5. **Catch-up carousel** — swipe left/right for missed days
6. **Streak logic** — calculation, repair, freeze, milestone detection
7. **Journal calendar** — reading days visualization, retroactive marking
8. **Library screen** — book list with filtering, search, add book (manual + Google Books)
9. **Book detail screen** — view/edit book, progress tracking
10. **Optional detail logging** — link check-ins to books, log pages
11. **Basic statistics** — streak stats, books completed, pages read
12. **Settings** — theme, reminders, data export/import
13. **Dark mode** — system-native appearance support

### Phase 2: Kindle + Platform Features
1. **Kindle sync** — background sync, auto-fill check-ins from Kindle activity
2. **Home screen widget** — streak counter + quick check-in
3. **Barcode scanning** — ISBN scanner to add physical books
4. **Gentle notifications** — opt-in reading reminders
5. **Share streak** — generate shareable milestone images
6. **Goal tracking** — create goals, display progress with celebrations

### Phase 3: Advanced Features
1. **iCloud sync** — CloudKit-backed SwiftData for multi-device
2. **Apple Watch** — check-in complication, streak glance
3. **Siri & Shortcuts** — "Hey Siri, I read today" via App Intents
4. **Live Activities** — reading session timer on Dynamic Island
5. **iPad layout** — multi-column adaptive layout

---

## 12. Key Technical Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Primary interaction | Daily check-in button | Lowest friction, celebrates the habit itself |
| Celebration engine | Lottie + SwiftUI animations | Rich confetti/milestone animations without custom rendering |
| Streak philosophy | Guilt-free (Finch-inspired) | Repair, freeze, compassionate language — promotes mental health |
| Persistence | SwiftData | Mirrors the offline-first IndexedDB approach |
| No backend required | Yes (Phase 1-2) | Same local-storage model as web |
| Kindle sync server | Reuse existing tls-client-api | No new infrastructure needed |
| Charts | Swift Charts | Native framework, no dependencies |
| Image caching | Nuke | Mature, performant, SwiftUI support |
| Min iOS version | 17 | SwiftData, modern SwiftUI, Swift Charts |
| Package manager | Swift Package Manager | Standard for Swift projects |

---

## 13. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Check-in feels too simple | Users may want more depth | Progressive disclosure — details are always available, never required |
| Celebration fatigue | Confetti gets old after 30 days | Vary animations, introduce new milestones, let users customize celebration intensity |
| Catch-up becomes tedious | Many missed days = many swipes | "Skip catch-up" option always visible; cap at ~7 days, older days auto-mark as "no" |
| Kindle API instability | Sync breaks if Amazon changes APIs | Graceful degradation; sync is P2, core app works without it |
| tls-client-api hosting | Requires running a server for Kindle sync | Document self-hosting options; make URL configurable |
| No web↔iOS sync initially | Users have data in both places | JSON export/import bridges the gap in Phase 1 |
| SwiftData maturity | Potential bugs in newer framework | Fallback to Core Data if critical issues found |
| App Store review for Kindle integration | Amazon credential storage may raise concerns | Store in Keychain; clearly document user consent |

---

## 14. Estimated Scope

| Phase | Screens | Services | Core Focus |
|-------|---------|----------|-----------|
| Phase 1 (MVP) | 8 screens | 7 services | Check-in, celebrations, streaks, library, journal |
| Phase 2 (Kindle + Widgets) | +3 screens | +1 service | Kindle sync, widgets, notifications, goals |
| Phase 3 (Advanced) | +2 screens | — | iCloud, Watch, Siri, iPad |

---

## Summary

Raquel Reads iOS is **a reading habit app first, and a book tracker second.** The core experience is a single tap: "I read today." Everything else — which book, how many pages, Kindle sync, statistics — layers on top for users who want depth, but never gets in the way of the simple daily ritual.

The app celebrates showing up. It never punishes absence. It meets readers where they are, whether they finished a 400-page novel or read one poem on the bus. Because the goal isn't to track books — it's to build a life where reading happens.
