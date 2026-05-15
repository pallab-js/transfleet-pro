# TransFleet Pro

A comprehensive, offline-first macOS desktop application for managing all aspects of a mixed-fleet transportation business. Built with Swift 6 and SwiftUI.

## Features

- **Dashboard** — Key performance indicators, trip trends, fleet utilization charts, and quick actions
- **Fleet Management** — Vehicle tracking, maintenance scheduling, and fuel log recording
- **Driver Management** — Driver profiles, license/certification tracking, availability, and performance metrics
- **Trips & Dispatch** — End-to-end trip lifecycle: creation, assignment, tracking, and delivery
- **Customer Management** — Contact management, credit limits, payment terms, and billing
- **Finance** — Invoicing, expense tracking, revenue dashboard, and profit margin analysis
- **Reports** — Fleet utilization, driver performance, revenue, expenses, and P&L statements
- **Settings** — Business profile, user preferences, data backup/restore, and invoice configuration

## Tech Stack

- **Language:** Swift 6.0+
- **UI Framework:** SwiftUI (macOS 14+)
- **Architecture:** MVVM with Repository Pattern
- **Database:** SQLite (via SQLite.swift) — offline-first, local storage
- **Charts:** Swift Charts (native Apple framework)
- **Build System:** Swift Package Manager + XcodeGen

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0+

## Development Setup

```bash
# Install XcodeGen (if not already installed)
brew install xcodegen

# Generate Xcode project from project.yml
xcodegen generate

# Open the project
open TransFleetPro.xcodeproj
```

## Building

Open the project in Xcode and build (⌘B), or run directly (⌘R).

## License

MIT
