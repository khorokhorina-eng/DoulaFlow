# DoulaFlow App

MVP SwiftUI + Supabase application that lets doulas manage profiles, clients, birth plans, recommendations, and share tokenized mini-cabinets.

## Repository Layout
- `docs/architecture.md` – Product & technical architecture
- `DoulaFlow/Package.swift` – Swift Package entry with iOS 15+ target
- `DoulaFlow/Sources` – SwiftUI app, models, view models, services
- `DoulaFlow/Tests` – Lightweight XCTest coverage

## Getting Started
1. Open Xcode 15+, choose **File → Open**, select the `DoulaFlow/Package.swift` file to generate the project.
2. Update `AppServices` with your real Supabase project URL and anon key.
3. Build & run the app scheme on an iOS 15+ simulator:
   - In many Xcode setups this scheme is named `BirthPrepPro` (the executable product name).
   - Depending on how Xcode generated schemes, you may instead see `DoulaFlowApp`.

## Next Steps
- Replace `MockDataStore` with live Supabase repositories.
- Hook up PDF export + file upload pipelines.
- Implement Supabase Edge Functions for public mini-cabinet sharing.
