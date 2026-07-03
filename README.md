# JobTracker

A Flutter Android app for tracking job applications — built with a pastel Material 3 design and offline-first SQLite storage.

## Screenshots

> Home screen with pipeline infographic, Stats page with donut gauges and conversion funnel, modern form with pill status selector.

## Features

- **Pipeline overview** — tappable stage cards (Wishlist → Applied → Phone Screen → Interview → Offer) that filter your list instantly
- **Stats page** — gradient hero card, circular ring gauges for response & interview rates, conversion funnel, weekly trend chart
- **Modern form** — visual pill status grid, 5-star priority selector, no dropdowns
- **Search & filter** — live search + status chip filters
- **Swipe to delete** — swipe left on any card to remove it (with confirmation)
- **Excel import** — import from `.xlsx` via Settings tab
- **Local notifications** — reminder scheduling with exact alarm support
- **Fully offline** — SQLite via `sqflite`, no account or internet required

## Tech Stack

| Layer | Library |
| --- | --- |
| UI | Flutter 3.x / Material 3 |
| Database | `sqflite` + `path` |
| Charts | `fl_chart` |
| Excel import | `excel` + `file_picker` |
| Notifications | `flutter_local_notifications` |
| State | `StatefulWidget` + `IndexedStack` |

## Getting Started

### Prerequisites

- Flutter 3.10+ (`flutter --version`)
- Android device or emulator (API 21+)

### Run locally

```bash
git clone https://github.com/T0pN0xch/JobTracker.git
cd JobTracker
flutter pub get
flutter run
```

### Build release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Project Structure

```text
lib/
├── data/           # Seed data (example companies)
├── db/             # SQLite database helper
├── models/         # JobApplication model & JobStatus enum
├── screens/        # Home, Stats, Settings, AddEdit screens
├── services/       # Import service, notification service
├── theme/          # AppColors + AppTheme (design system)
└── widgets/        # ApplicationCard widget
```

## Excel Import

Go to **Settings → Import from Excel** and pick your `.xlsx` file. The app maps columns for company, position, status, source, location, link, and notes.

> **Note:** Any column containing credentials is intentionally never read or stored.

## License

MIT
