# DoulaFlow MVP Technical Architecture

## 1. Guiding Principles
- **Single source of truth** per entity (profile, clients, plans, recommendations) stored in Supabase Postgres.
- **MVVM + SwiftUI** on the client for predictable state and simple testability.
- **Offline-first reads, online writes**: profile, clients, and plans are cached locally via `FileStorage` + `AppStorage` mirrors so the doula can review data without network. Writes queue via Combine pipelines and retry when connectivity returns.
- **Composable PDF pipeline** using SwiftUI views rendered by `PDFKit` to guarantee identical data between onscreen previews and exports.
- **Tokenized public links** served by a lightweight Supabase Edge Function that renders mobile-first HTML (mini-cabinet) and streams Supabase Storage assets.

## 2. High-Level System Overview

```
+-------------+        HTTPS / Supabase Swift SDK        +--------------------+
|  DoulaFlow  | <--------------------------------------> | Supabase (Postgres |
| iOS Client  |                                          |  + Storage + Auth) |
+-------------+                                          +--------------------+
      |                                                              |
      | (export)                                                     |
      v                                                              v
+------------------+                                 +------------------------------+
| Local PDFKit     |                                 | Edge Function (mini-cabinet) |
| render & share   |                                 | SSR HTML + token validation  |
+------------------+                                 +------------------------------+
```

## 3. Platform & Tooling
- **Language/Frameworks**: Swift 5.9+, SwiftUI, Combine, PDFKit, UniformTypeIdentifiers, QuickLook for previews.
- **Backend**: Supabase (managed Postgres + Row Level Security + Storage + Edge Functions). Auth uses email+password for doulas; clients only use token links.
- **3rd-Party SDKs**: `SwiftSoup` (HTML sanitization for rich text), `PhotosUI` for picking profile photos, `FirebaseCrashlytics` (optional) for crash reporting.
- **Build Targets**: iOS 15+. Deployment through Xcode project `DoulaFlow.xcodeproj` with Swift Package Manager for dependencies.

## 4. App Architecture
- **Entry Point**: `DoulaFlowApp` bootstraps Supabase client, loads persisted session, and injects dependencies via `@Environment(\.services)`.
- **Navigation Shell**: `TabView` with `ProfileView`, `ClientsView`, `TemplatesView/SettingsView`.
- **State Management**: Each module has `ViewModel` conforming to `ObservableObject` that exposes `@Published` state structs. All network/data operations flow through dedicated service protocols.

```
View -> ViewModel -> UseCase -> Repository -> SupabaseClient
               ^                         |
               |-------------------------|
```

### Core Modules
1. **Profile**
   - `ProfileViewModel` loads/saves `DoulaProfile` via `ProfileRepository`.
   - PDF export: `ProfilePDFComposer` renders `ProfilePreviewView` into PDF.
2. **Clients**
   - `ClientsListViewModel` streams `ClientSummary` list (sorted by EDD) using Supabase real-time channels.
   - Detail screen hosts tabs for Profile, Birth Plan, Recommendations.
3. **Birth Plans**
   - Schema stored as JSON array of sections `{ id, title, body, lastUpdated }`.
   - Template loader fetches static JSON from bundled assets and user-defined templates from Supabase `templates` table.
4. **Recommendations**
   - Rich text editor via `UIViewRepresentable` wrapper around `UITextView` enabling markdown-ish controls (bold, list, headings).
   - Attachments stored in Supabase Storage bucket `recommendations/<clientId>/` with metadata saved alongside content.
5. **Public Mini-Cabinet**
   - Edge Function `serveClientCabinet` validates `token`, fetches aggregated payload, renders Tailwind-lite HTML, and disables indexing via headers (`X-Robots-Tag: noindex`).

## 5. Backend Design (Supabase)

### Tables
- `doula_profile`: single row per doula (RLS ensures owner-only access).
- `clients`: `edd` stored as DATE; `pregnancy_week` computed via generated column or view.
- `birth_plans`: `content JSONB`, `pdf_url TEXT`, `template_id UUID?`.
- `recommendations`: `content TEXT (Markdown)`, `attachments JSONB [{name,url,type}]`.
- `public_links`: `token UUID`, `expires_at TIMESTAMPTZ`, `disabled BOOLEAN`.
- `templates`: stores reusable birth plans & recommendation snippets.

### Edge Functions / RPC
1. `generate_public_link(client_id)` → creates token, stores hashed version.
2. `revoke_public_link(token)`.
3. `compute_pregnancy_week(edd)` (or calculated in-app if offline).

### Security
- Enable RLS with policies: `auth.uid() = doula_id` for private tables.
- Public link function performs `select` without auth but only returns sanitized payload.
- Storage bucket policies separate `profile`, `client-files`, `recommendations` with read restrictions (public links rely on signed URLs).

## 6. Data Models (Swift)

```swift
struct DoulaProfile: Identifiable, Codable {
    var id: UUID
    var fullName: String
    var title: String
    var experienceSummary: String
    var bio: String
    var photoURL: URL?
    var contactEmail: String
    var phone: String
    var website: URL?
    var certifications: [String]
}

struct Client: Identifiable, Codable {
    enum Status: String, Codable { case onboarding, preparing, approaching, postpartum }
    var id: UUID
    var doulaId: UUID
    var name: String
    var contact: String
    var edd: Date
    var pregnancyWeek: Int
    var status: Status
    var notes: String
    var medicalNotes: String?
}

struct BirthPlanSection: Identifiable, Codable {
    var id: UUID
    var title: String
    var body: String
}
```

## 7. Feature Workflows
- **Client Creation**: `ClientsView` → `ClientFormView`. Form validates required fields, calculates pregnancy week (using `Calendar` diff) and saves via `ClientRepository`. Upon success, user offered to create birth plan immediately.
- **Birth Plan Editing**: Doula selects template, edits text blocks, attaches checklist. Autosave every 10 seconds locally; manual save pushes to Supabase and regenerates PDF if flagged.
- **Recommendations**: Editor supports quick-formatting toolbar; attachments uploaded via `FileImporter`. Each attachment produces signed URL stored in `recommendations.attachments`.
- **PDF Export**: `PDFComposer` accepts `PDFRenderable` protocol implemented by profile, client, and birth plan views. Output saved locally, optionally uploaded to Supabase Storage for sharing.
- **Public Link Sharing**: From client detail, user taps “Share mini-cabinet”. App calls Edge Function, receives tokenized URL, presents `ShareLink`. Cabinet fetches data via REST call to Supabase Edge Function using token query param.

## 8. File Handling Strategy
- Use `UIDocumentPicker` / `PhotosPicker` for imports.
- Files stored under `client-files/<clientId>/<slug>` with MIME metadata.
- Local caching in `FileManager.default.urls(for: .documentDirectory, ...)` with reference table for offline preview.

## 9. PDF + Branding
- `PDFTheme` struct centralizes typography/colors (e.g., Playfair Display headings, SF Pro body, accent color #8E97FD).
- Header includes app name “DoulaFlow” + doula avatar; footers show contact info and generated timestamp.
- All links (email, website, attachments) rendered as tappable `LinkAnnotation`s.

## 10. Templates & Settings Tab
- Templates tab lists bundled JSON templates plus user-generated ones.
- Settings host: sign-out, data export, diagnostics toggle, default statuses, default birth plan structure.

## 11. Public Mini-Cabinet Frontend
- Tech: Supabase Edge Function + Deno deploy, outputs HTML styled with Pico.css or custom CSS.
- Content blocks: client name + EDD, pregnancy week, birth plan sections, recommendations (rendered Markdown→HTML), file list (signed URLs expiring after 1h).
- Accessibility: large tap targets, standard fonts, ensures Safari readability.

## 12. Delivery Roadmap
1. **Week 1**: Project scaffolding, Supabase schema + auth wiring, profile module skeleton.
2. **Week 2**: Client CRUD, birth plan editor core, local caching.
3. **Week 3**: Recommendations module, attachments, templates.
4. **Week 4**: PDF pipeline, mini-cabinet Edge Function, polish + QA.

## 13. Testing & QA
- Unit tests for repositories + view models using `XCTest` with Supabase mock client.
- Snapshot tests for key SwiftUI views.
- Integration test harness for PDF export to ensure deterministic output.
- Edge Function tests via `supabase functions serve` + Deno test runner.

## 14. Open Questions / Assumptions
- Single doula per app instance (no team account).
- Email sending for public links handled by share sheet, not automated.
- No push notifications or scheduling until future iteration.

## 15. MVP Deliverables Checklist
### Frontend (SwiftUI)
- Tab navigation shell + dependency container
- Profile editor, preview, PDF/share sheet
- Client list (EDD-sorted), CRUD forms, status badges
- Birth plan editor with template picker and checklist support
- Recommendations editor (rich text + attachments)
- File picker flows + attachment previewers
- Settings/Templates tab: template manager, auth, diagnostics toggle

### Backend (Supabase)
- SQL migration files for tables + RLS policies
- Storage buckets (`profile`, `client-files`, `recommendations`, `pdf-exports`)
- Edge Functions: `generate_public_link`, `serve_client_cabinet`, `revoke_link`
- REST adapters / RPC wrappers inside iOS app

### Mini-Cabinet Web
- Responsive HTML template + CSS tokens
- Token validation + payload fetch inside Edge Function
- Birth plan + recommendations renderer (Markdown → HTML)
- Attachment list with signed URLs and expiry handling

### Shared Utilities
- `PDFComposer` + theming assets
- `FileStorageService` for caching downloads/uploads
- `TemplateProvider` with bundled JSON seed data
- Localization scaffold (English strings file) to support future expansion

### Assets & Samples
- Color palette + typography guideline stored in `DesignTokens.swift`
- Placeholder icons (SF Symbols mapping list)
- Sample birth plan & recommendation templates for onboarding
