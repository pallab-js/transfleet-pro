# TransFleet Pro

A comprehensive, offline-first macOS desktop application for managing all aspects of a mixed-fleet transportation business. Built with Swift 6 and SwiftUI.

## Features

- **Dashboard** — KPIs, trip trends, fleet utilization charts, revenue tracking, and quick actions
- **Fleet Management** — Vehicle CRUD, maintenance scheduling, fuel logging, and status tracking
- **Driver Management** — Driver profiles, license/certification tracking, availability, and ratings
- **Trips & Dispatch** — End-to-end trip lifecycle: creation, assignment, tracking, and delivery
- **Customer Management** — Contact management, credit limits, payment terms, and billing
- **Finance** — Invoicing with junction-table trip linking, expense tracking, and P&L analysis
- **Reports** — Revenue trends, expense breakdown, fleet utilization, trip distribution, and P&L
- **Settings** — Business profile, preferences, data export/import, and invoice configuration

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Swift 6.0+ |
| UI Framework | SwiftUI (macOS 14+) |
| Architecture | MVVM with Repository Pattern & Protocol-based DI |
| Database | SQLite via SQLite.swift — offline-first, local storage |
| Charts | Swift Charts (native Apple framework) |
| Build System | Swift Package Manager + XcodeGen |
| Testing | XCTest |

## Architecture

```
Sources/
├── App/                    # App entry point, AppState, navigation
├── Models/                 # Data models, enums, value types
├── Services/
│   ├── DatabaseManager.swift        # SQLite CRUD, migrations, aggregates
│   └── DatabaseManagerProtocol.swift # Protocol for dependency injection
├── ViewModels/             # @MainActor ObservableObject view models
└── Views/
    ├── Components/         # Reusable UI (StatusBadge, SearchField, Charts, Pagination)
    ├── Dashboard/          # KPI dashboard
    ├── Fleet/              # Vehicle management
    ├── Drivers/            # Driver management
    ├── Trips/              # Trip dispatch
    ├── Customers/          # Customer management
    ├── Finance/            # Invoices & expenses
    ├── Reports/            # Analytics charts
    └── Settings/           # App configuration
```

### Key Design Decisions

- **Protocol-based DI** — `DatabaseManagerProtocol` enables unit testing with mock repositories
- **Async database calls** — All ViewModel DB operations use `Task {}` with `try`/`catch`
- **Cascade deletes** — Deleting a vehicle/driver/trip/customer cascades to related records
- **Transaction wrapping** — All save/delete operations run in SQLite transactions
- **Junction table** — Invoice-trip relationships use `invoice_trips` instead of comma-separated IDs
- **Schema migrations** — Version-based migration system with DDL support
- **Pagination** — List views support 25/50/100 items per page

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0+ (for XcodeGen) or Swift 6.0+ toolchain

## Quick Start

```bash
# Clone the repository
git clone https://github.com/pallab-js/transfleet-pro.git
cd transfleet-pro

# Build and run via Swift Package Manager
swift run

# Or generate Xcode project
brew install xcodegen
xcodegen generate
open TransFleetPro.xcodeproj
```

## Testing

```bash
# Run unit tests
swift test
```

Tests cover data models, enum properties, Codable conformance, and business logic.

## Project Structure

| File | Lines | Purpose |
|------|-------|---------|
| `DatabaseManager.swift` | ~2000 | All SQLite operations, migrations, import/export |
| `ViewModels.swift` | ~510 | All MVVM view models with async DB calls |
| `Models.swift` | ~360 | All data models and enums |
| `Components/` | 8 files | Reusable UI components |

## License

MIT License — see [LICENSE](LICENSE) for details.
