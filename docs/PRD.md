# Product Requirements Document (PRD)
## Athena Flutter Mobile App
**Version:** 1.0
**Date:** 2026-02-27
**Platform:** Flutter (Dart) — iOS & Android
**Backend:** Athena Core API v1.0.0

---

## 1. Product Overview

The Athena Flutter app is the mobile client for the Athena Core API. It lets users connect to their self-hosted Athena server, manage documents, and ask AI-powered questions grounded exclusively in their uploaded content.

**App Name:** Athena
**Tech Stack:** Flutter + Dart
**State Management:** Riverpod (preferred) or Provider
**HTTP Client:** `dio` package (supports SSE streaming)
**Secure Storage:** `flutter_secure_storage`
**File Picker:** `file_picker`
**Navigation:** `go_router`

---

## 2. Screen Inventory

| Screen | Route | Description |
|---|---|---|
| Splash / Onboarding | `/` | First-launch setup check |
| Settings (Setup) | `/settings` | Configure server URL + API key |
| Home / Dashboard | `/home` | Health status + quick actions |
| Documents | `/documents` | Document library list |
| Upload Document | `/upload` | Upload form (file + title + year) |
| Ask | `/ask` | Question input + answer display |
| Answer Detail | `/answer` | Full answer + citations |

---

## 3. Feature Specifications

---

### F-1: Connection Setup (Settings Screen)

**Priority:** Must Have

**Description:**
On first launch (or when no server is configured), the user is directed to the Settings screen to enter their Athena Core API server details.

**Fields:**
| Field | Type | Validation |
|---|---|---|
| Server URL | Text input | Required. Must start with `http://` or `https://`. No trailing slash enforced by the app. |
| API Key | Text input (obscured) | Required. Non-empty string. |

**Behaviors:**
- "Test Connection" button calls `GET /api/health` with the entered credentials
- On success: shows a green status card with server health info (DB status, model loaded, chunk count)
- On failure (network error, 403, timeout): shows a red error message with detail
- On save: stores both values securely using `flutter_secure_storage`
- The eye icon toggles API key visibility
- Settings are accessible any time from the app bar or drawer
- After a successful test + save, the user is navigated to `/home`

**API Call:**
```
GET {server_url}/api/health
Headers: X-API-Key: {api_key}
```

**UI Elements:**
- Server URL field (keyboard: URL type)
- API Key field (obscured, with visibility toggle)
- "Test Connection" button (shows loading spinner while testing)
- Status card (green ✓ / red ✗) with health details
- "Save & Continue" button (enabled after successful test)

---

### F-2: Home / Dashboard Screen

**Priority:** Must Have

**Description:**
The main landing screen after setup. Shows a real-time health status of the connected server and quick-action buttons.

**Sections:**
1. **Server Status Card** — shows `status`, `database`, `model_loaded`, `total_chunks`, `indexed_chunks` from `/api/health`
2. **Quick Actions** — "Ask a Question" button, "Upload Document" button, "View Documents" button
3. **Status indicators:**
   - Green dot: `status == "ok"`
   - Yellow dot: `status == "degraded"` (DB disconnected)
   - Red dot: API unreachable

**Behaviors:**
- Health check is called on screen mount and every 30 seconds while the screen is active
- If the server becomes unreachable, show a non-dismissible banner: "Server unreachable. Check your connection settings."
- "Ask a Question" navigates to `/ask`
- "Upload Document" navigates to `/upload`
- "View Documents" navigates to `/documents`

**API Call:**
```
GET {server_url}/api/health
Headers: X-API-Key: {api_key}
```

---

### F-3: Documents Screen (Library)

**Priority:** Must Have

**Description:**
Displays all indexed documents as a scrollable list. Each document card shows its title, year, section count, and upload date.

**Document Card Fields:**
| Field | Source |
|---|---|
| Title | `document.title` |
| Year | `document.year` |
| Section Count | `document.section_count` (labeled "sections" or "chunks indexed") |
| Uploaded At | `document.created_at` (formatted as `MMM d, yyyy`) |

**Behaviors:**
- List is fetched on mount and on pull-to-refresh
- Empty state: illustration + "No documents yet. Upload your first document."
- Loading state: shimmer placeholder cards
- Error state: retry button + error message
- Each card has a delete icon (trailing) that shows a confirmation bottom sheet:
  - Title: "Delete document?"
  - Body: "This will permanently remove **{title}** and all its indexed content. This cannot be undone."
  - Actions: "Cancel" (dismiss) | "Delete" (red, calls API)
- After delete: the card animates out and the list refreshes
- A floating action button (FAB) navigates to `/upload`

**API Calls:**
```
GET {server_url}/api/documents
Headers: X-API-Key: {api_key}
Response: { "data": [Document] }

DELETE {server_url}/api/document/{document_id}
Headers: X-API-Key: {api_key}
Response: 204 No Content
```

**Error Handling:**
- 404 on delete: "Document not found. It may have already been deleted."
- 500: "Server error. Please try again."

---

### F-4: Upload Document Screen

**Priority:** Must Have

**Description:**
A form screen where the user picks a file, enters a title and year, then uploads to the API.

**Form Fields:**
| Field | Type | Validation |
|---|---|---|
| File | File picker (tap to select) | Required. `.pdf` or `.txt` only. Max 50 MB. |
| Title | Text input | Required. 2–200 characters. |
| Year | Number input | Required. 1900–2100. |

**Behaviors:**
- File picker: opens device file browser, filters to `.pdf` and `.txt`
- After file selection: shows file name, file size (human-readable, e.g. "2.3 MB"), and file type badge
- If file size > 50 MB: show error immediately — "File is too large. Maximum size is 50 MB." — do not allow submit
- If file type not allowed: show error immediately — "Only PDF and TXT files are supported."
- Title field: pre-populated with the filename (without extension) for convenience — user can edit
- Year field: pre-populated with the current year — user can edit
- "Upload" button: disabled until form is valid; shows loading spinner + progress indicator during upload
- Upload is done as `multipart/form-data`
- On success (201): show a success snackbar "Document uploaded and indexed successfully ({n} sections)". Navigate back to `/documents`.
- On failure: show error snackbar with the API detail message

**Upload Progress:**
- Show an indeterminate linear progress bar during upload (upload can take 5–60s for large files)
- Show cancel button during upload (cancels the request)

**API Call:**
```
POST {server_url}/api/upload-document
Headers:
  X-API-Key: {api_key}
  Content-Type: multipart/form-data
Body (form fields):
  file: <binary>
  title: <string>
  year: <integer>
Response (201):
{
  "data": {
    "id": "uuid",
    "title": "string",
    "year": 2024,
    "chunks_indexed": 42,
    "strategy": "sections" | "fixed_size"
  }
}
```

**Error Handling:**
| HTTP Status | Displayed Message |
|---|---|
| 400 | Show `detail` from response directly (e.g., "Unsupported file type") |
| 403 | "Invalid API key. Check your settings." |
| 500 | "Server error during indexing. Please try again." |
| Network | "Could not reach the server. Check your connection." |

---

### F-5: Ask Screen

**Priority:** Must Have

**Description:**
The primary interaction screen. Users type a question and receive a streaming AI answer with citations.

**Layout:**
```
┌─────────────────────────────┐
│  [←]  Ask a Question        │
├─────────────────────────────┤
│                             │
│  [Previous answers appear   │
│   as a scrollable chat-     │
│   style history above]      │
│                             │
├─────────────────────────────┤
│ [Question input field  ] [▶]│
└─────────────────────────────┘
```

**Behaviors:**

**Input:**
- Multi-line text field, max 2,000 characters
- Character counter shown when > 1,800 characters
- Send button disabled when: (a) input is < 5 chars, (b) a request is in progress
- Keyboard "send" action triggers submission

**Streaming Answer:**
- Uses `POST /api/ask/stream` (SSE)
- Tokens are appended to the answer bubble as they arrive (typewriter effect)
- A blinking cursor indicator shows while streaming
- Citations appear below the answer text after streaming completes
- "Stop" button cancels the stream mid-generation

**Citations Display:**
- Rendered below the answer as a collapsible "Sources" section
- Each citation shows: document name + section label
- Tapping a citation opens a bottom sheet with the full citation detail

**Answer History:**
- Previous Q&A pairs are shown above as a chat-style list
- User bubble (right-aligned): the question
- Assistant bubble (left-aligned): the answer + citations
- Persist history in-memory for the session (not saved to disk)

**No-Context Response:**
- If the API returns the no-context string, show it in the assistant bubble with an info icon
- Message: "No information found in your uploaded documents. Try uploading a relevant document first."

**Empty State (no documents):**
- If `/api/health` shows `total_chunks == 0`, show a banner: "No documents indexed yet. Upload a document to start asking questions." with an "Upload" shortcut.

**API Calls:**
```
POST {server_url}/api/ask/stream
Headers:
  X-API-Key: {api_key}
  Content-Type: application/json
  Accept: text/event-stream
Body:
  { "question": "string", "top_k": 3 }

SSE Events:
  data: {"token": "string"}         <- append to answer
  data: {"citations": [...]}        <- set citations list
  data: {"error": "string"}         <- show error
  data: [DONE]                      <- stop streaming
```

**Fallback (non-streaming):**
- If SSE fails, automatically retry with `POST /api/ask`
- Show loading spinner instead of typewriter effect

---

### F-6: App Navigation

**Priority:** Must Have

**Navigation Structure:**
```
Bottom Navigation Bar (3 tabs):
  1. Ask          → /ask
  2. Documents    → /documents
  3. Settings     → /settings
```

- The Home/Dashboard is the default landing after setup (can be the Ask tab)
- Back navigation follows standard Flutter/platform conventions
- Deep link: `/upload` accessible from Documents tab FAB and Home quick action

---

### F-7: Error Handling & Offline State

**Priority:** Must Have

**Global Error States:**

| Scenario | UI Behavior |
|---|---|
| No server configured | Redirect to Settings immediately |
| Server unreachable (any screen) | Show a top banner: "Server offline" with a retry button |
| 403 Forbidden | Show snackbar: "Invalid API key. Update in Settings." |
| 422 Validation error | Show field-level errors from `detail[].msg` |
| 500 Server Error | Show snackbar with detail text |
| Network timeout | Show snackbar: "Connection timed out. Check your network." |

**Request Timeout:** 30 seconds for all non-streaming calls. Streaming uses 60 seconds for first token.

---

### F-8: Theming & UI Design

**Priority:** Should Have

**Design System:**
- Material Design 3 (Flutter's `useMaterial3: true`)
- Light mode + Dark mode (respects system preference)
- Custom color seed: deep navy / indigo (professional feel)

**Typography:**
- System font (SF Pro on iOS, Roboto on Android)
- Question text: `bodyLarge`
- Answer text: `bodyMedium`
- Citations: `labelSmall` with muted color

**Color Roles:**
| Role | Usage |
|---|---|
| Primary | Action buttons, active tab, FAB |
| Error | Delete confirmations, error states |
| Surface | Cards, bottom sheets |
| On-surface-variant | Placeholder text, metadata labels |

**Component Specifications:**
- Document cards: `Card` with `elevation: 1`, rounded corners 12px
- Answer bubbles: chat-style, user = primary color tint, assistant = surface
- Citations: chip-style badges with document icon
- Loading: `shimmer` effect for lists; `CircularProgressIndicator` for actions
- Success/error feedback: Material 3 `SnackBar` with action

---

## 4. User Stories

### Setup & Connection
- **US-1:** As a new user, I want to enter my server URL and API key so that the app connects to my Athena server.
- **US-2:** As a user, I want to test my connection before saving so that I know it works before proceeding.
- **US-3:** As a user, I want my settings saved securely so that I don't need to re-enter them every time.

### Document Management
- **US-4:** As a user, I want to upload a PDF or TXT file so that I can ask questions about it.
- **US-5:** As a user, I want to see all my indexed documents so that I know what's available to query.
- **US-6:** As a user, I want to delete a document so that I can remove content I no longer need.
- **US-7:** As a user, I want to see how many sections were indexed from my document so that I understand the coverage.

### Asking Questions
- **US-8:** As a user, I want to type a question and receive a streaming AI answer so that I see results appear immediately.
- **US-9:** As a user, I want to see citations with each answer so that I can verify which document and section the answer came from.
- **US-10:** As a user, I want to be clearly told when the AI cannot find an answer in my documents so that I know to upload more content.
- **US-11:** As a user, I want to stop a streaming answer mid-generation so that I can ask a different question.

### System Health
- **US-12:** As a user, I want to see if my server is online and the AI model is loaded so that I know the system is ready.

---

## 5. Data Models (Dart)

```dart
// Connection config (stored securely)
class ServerConfig {
  final String serverUrl;    // e.g., "http://192.168.1.100:8001"
  final String apiKey;       // e.g., "my-secret-key"
}

// Health response
class HealthStatus {
  final String status;       // "ok" | "degraded"
  final String database;     // "connected" | "disconnected"
  final bool modelLoaded;
  final int totalChunks;
  final int indexedChunks;
}

// Document (from GET /api/documents)
class Document {
  final String id;           // UUID string
  final String title;
  final int year;
  final int sectionCount;
  final DateTime createdAt;
}

// Upload result
class UploadResult {
  final String id;
  final String title;
  final int year;
  final int chunksIndexed;
  final String strategy;    // "sections" | "fixed_size"
}

// Ask request
class AskRequest {
  final String question;    // 5–2000 chars
  final int topK;           // default 3, range 1–20
}

// Citation
class Citation {
  final String document;    // document title
  final String section;     // section label
}

// Ask response (full + streaming assembled)
class AskResponse {
  final String answer;
  final List<Citation> citations;
}

// Chat message (in-session history)
class ChatMessage {
  final String role;        // "user" | "assistant"
  final String content;
  final List<Citation> citations;  // only for "assistant"
  final DateTime timestamp;
}
```

---

## 6. API Integration Notes

### Authentication
Every request must include:
```
X-API-Key: {stored api_key}
```

### SSE Streaming (dio + EventSource pattern)
```dart
// Use dio with ResponseType.stream
// Parse each line:
// - Skip empty lines
// - Strip "data: " prefix
// - If content == "[DONE]" → complete
// - Parse JSON → check for "token", "citations", "error" keys
```

### Multipart Upload
```dart
FormData formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(filePath, filename: fileName),
  'title': title,
  'year': year.toString(),
});
```

### Error Parsing
```dart
// On non-2xx:
// - Try to parse { "detail": "string" } → show detail
// - On { "detail": [{ "loc", "msg", "type" }] } → show first msg
// - On parse failure → show generic error
```

---

## 7. Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR-1 | App cold start < 2 seconds |
| NFR-2 | All API calls have 30-second timeouts (60s for streaming first byte) |
| NFR-3 | Secure storage used for server URL and API key (never in SharedPreferences) |
| NFR-4 | App works on iOS 14+ and Android 8+ (API level 26+) |
| NFR-5 | Supports both portrait and landscape on phones |
| NFR-6 | Handles screen readers (accessibility labels on all interactive elements) |
| NFR-7 | No sensitive data (URL, API key) logged to console in release builds |

---

## 8. Acceptance Criteria

| Feature | Acceptance Criteria |
|---|---|
| F-1 Setup | Given a valid server URL and API key, when I tap "Test Connection", then I see the server health details. Given invalid credentials, I see a clear error message. |
| F-3 Documents | Given documents are indexed, when I open the library, I see a list with title, year, section count. When I swipe/tap delete and confirm, the document is removed. |
| F-4 Upload | Given a valid PDF ≤ 50 MB, when I fill in title + year and tap Upload, the document is indexed and I'm shown the chunk count. Given a file > 50 MB, I see an error before upload begins. |
| F-5 Ask | Given a question with ≥ 5 characters, when I send it, tokens stream into the answer bubble. After streaming, citations are shown. Given the AI finds no answer, the no-context message is shown. |
| F-7 Errors | Given the server is unreachable, I see a banner. Given a 403 error, I see "Invalid API key". Given a 422, I see the validation detail. |

---

## 9. Project Structure (Suggested)

```
lib/
├── main.dart
├── app.dart                    # MaterialApp + go_router setup
├── core/
│   ├── api/
│   │   ├── api_client.dart     # Dio instance, base URL, interceptors
│   │   ├── ask_api.dart        # POST /ask, POST /ask/stream
│   │   ├── documents_api.dart  # GET/DELETE /documents
│   │   ├── health_api.dart     # GET /health
│   │   └── upload_api.dart     # POST /upload-document
│   ├── models/
│   │   ├── document.dart
│   │   ├── health_status.dart
│   │   ├── ask_response.dart
│   │   ├── citation.dart
│   │   ├── chat_message.dart
│   │   └── server_config.dart
│   ├── storage/
│   │   └── secure_storage.dart # flutter_secure_storage wrapper
│   └── errors/
│       └── api_error.dart      # Error parsing utilities
├── features/
│   ├── settings/
│   │   ├── settings_screen.dart
│   │   └── settings_provider.dart
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── health_provider.dart
│   ├── documents/
│   │   ├── documents_screen.dart
│   │   ├── document_card.dart
│   │   └── documents_provider.dart
│   ├── upload/
│   │   ├── upload_screen.dart
│   │   └── upload_provider.dart
│   └── ask/
│       ├── ask_screen.dart
│       ├── answer_bubble.dart
│       ├── citation_chip.dart
│       └── ask_provider.dart
└── shared/
    ├── widgets/
    │   ├── error_banner.dart
    │   ├── loading_shimmer.dart
    │   └── confirm_dialog.dart
    └── theme/
        └── app_theme.dart
```

---

## 10. Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Navigation
  go_router: ^13.0.0

  # State management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # HTTP + SSE streaming
  dio: ^5.4.0

  # Secure storage
  flutter_secure_storage: ^9.0.0

  # File picking
  file_picker: ^8.0.0

  # UI utilities
  shimmer: ^3.0.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.0
```
