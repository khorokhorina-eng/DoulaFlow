# DoulaFlow App

MVP SwiftUI + Supabase application that lets doulas manage profiles, clients, birth plans, recommendations, and share tokenized mini-cabinets.

## Repository Layout
- `docs/architecture.md` – Product & technical architecture
- `DoulaFlow/Package.swift` – Swift Package entry with iOS 16+ target
- `DoulaFlow/Sources` – SwiftUI app, models, view models, services
- `DoulaFlow/Tests` – Lightweight XCTest coverage

## Getting Started
1. Open Xcode 15+, choose **File → Open**, select the `DoulaFlow/Package.swift` file to generate the project.
2. Add your Supabase project URL + anon key to `DoulaFlow/Sources/Info.plist` (and adjust the bundle identifier if you plan to run on device).
3. Build & run the `DoulaFlow` scheme on iOS 16+ simulators.

## Next Steps
- Replace `MockDataStore` with live Supabase repositories.
- Hook up PDF export + file upload pipelines.
- Implement Supabase Edge Functions for public mini-cabinet sharing.
