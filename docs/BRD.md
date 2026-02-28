# Business Requirements Document (BRD)
## Athena — Document Intelligence Mobile App
**Version:** 1.0
**Date:** 2026-02-27
**Backend:** Athena Core API v1.0.0 (FastAPI + pgvector + Qwen2.5-7B)

---

## 1. Executive Summary

Athena is an on-premise, privacy-first AI assistant that answers questions exclusively from documents that the user has uploaded. No data leaves the local server. The mobile app (Flutter) is the primary client interface for the Athena Core API backend.

Users connect the app to their own Athena Core API server, upload documents (PDF or TXT), and ask natural-language questions. The AI responds with cited, document-grounded answers — never from its training data.

---

## 2. Business Goals

| ID  | Goal |
|-----|------|
| BG-1 | Allow professionals (lawyers, researchers, students, medical staff, corporate) to query their private document collections via mobile |
| BG-2 | Ensure complete data privacy — all processing is on the user's own server |
| BG-3 | Provide a clean, fast mobile UX that works across iOS and Android from a single codebase (Flutter) |
| BG-4 | Support document management: upload, view, and delete indexed documents |
| BG-5 | Deliver AI answers with proper source citations so users can verify responses |

---

## 3. Stakeholders

| Stakeholder | Role | Interest |
|---|---|---|
| End User | Primary user of the mobile app | Fast, reliable document Q&A on mobile |
| System Administrator | Runs the Athena Core API server | Server health, API key management |
| Developer | Builds and maintains the Flutter app | Clean architecture, testable code |

---

## 4. Scope

### In Scope
- Flutter mobile app (iOS + Android) connecting to a self-hosted Athena Core API
- API connection configuration (server URL + API key)
- Document upload (PDF and TXT files, ≤ 50 MB)
- Document library management (list, delete)
- Natural-language question asking with full and streaming response modes
- Citation display for AI answers
- System health status indicator
- Offline-aware error handling

### Out of Scope (v1.0)
- User authentication / multi-user accounts (API uses a single shared API key)
- Cloud-hosted Athena backend
- In-app PDF viewer
- Audio/voice input for questions
- Push notifications
- Android tablet / iPad specific layouts (handled by responsive design, but not optimized)

---

## 5. Business Rules

| ID | Rule |
|----|------|
| BR-1 | All API calls MUST include the `X-API-Key` header with the configured key |
| BR-2 | Only PDF and TXT files may be uploaded; other formats must be rejected before upload |
| BR-3 | Files larger than 50 MB must be rejected client-side before sending to the API |
| BR-4 | Questions must be between 5 and 2,000 characters |
| BR-5 | Deleting a document permanently removes all its indexed chunks; user must confirm before deletion |
| BR-6 | The app must handle the case where the API server is unreachable and show a clear error |
| BR-7 | If the API responds that no context was found, the app shows "No information found in uploaded documents" — not a generic error |
| BR-8 | Citations must always be displayed alongside an AI answer |
| BR-9 | The server URL and API key are stored securely on-device (Flutter Secure Storage) and persist across sessions |
| BR-10 | Streaming mode is the preferred answer mode; full (non-streaming) is a fallback option |

---

## 6. Constraints

| Constraint | Detail |
|---|---|
| Platform | Flutter (Dart) — targets iOS 14+ and Android 8+ |
| Connectivity | Requires network access to the configured Athena Core API server |
| File size | 50 MB max per upload (enforced client-side first, then server-side) |
| API auth | Single API key per server — no JWT, no user login |
| Offline mode | App is non-functional without server connection; must communicate this clearly |
| API base URL | Configurable — supports `http://` and `https://` |

---

## 7. Success Metrics (v1.0)

| Metric | Target |
|---|---|
| App launch to first question asked | < 3 minutes for a new user |
| Document upload success rate | > 95% for valid files |
| Streaming answer first-token latency | < 2 s (network-dependent) |
| Crash-free sessions | > 99% |
| User can configure server and ask a question without external documentation | Yes |

---

## 8. API Overview (Backend Contract)

The Flutter app communicates exclusively with the Athena Core API. All endpoints require `X-API-Key` header.

### Base URL
Configurable per device. Example: `http://192.168.1.100:8001`

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/health` | Server health, DB status, model loaded flag, chunk count |
| `POST` | `/api/upload-document` | Upload a PDF or TXT document (multipart/form-data) |
| `GET` | `/api/documents` | List all indexed documents |
| `DELETE` | `/api/document/{id}` | Delete a document and all its chunks |
| `POST` | `/api/ask` | Ask a question — returns full answer when complete |
| `POST` | `/api/ask/stream` | Ask a question — returns SSE streaming tokens |

### Standard Response Shape
```json
{ "data": { ... } }
```

### Error Response Shape
```json
{ "detail": "Error message here" }
```

### Document Object Shape
```json
{
  "id": "uuid-string",
  "title": "Document Title",
  "year": 2024,
  "section_count": 42,
  "created_at": "2024-01-01T00:00:00"
}
```

### Ask Response Shape
```json
{
  "data": {
    "answer": "The answer text...",
    "citations": [
      { "document": "Document Title", "section": "Section 3.1" }
    ]
  }
}
```

### Streaming SSE Format (POST /api/ask/stream)
```
data: {"token": "word"}        <- one per token
data: {"token": " "}           <- whitespace tokens
data: {"citations": [...]}     <- sent once at the end
data: [DONE]                   <- end of stream
data: {"error": "message"}     <- on error (before [DONE])
```

### Health Response Shape
```json
{
  "status": "ok",
  "database": "connected",
  "model_loaded": true,
  "total_chunks": 150,
  "indexed_chunks": 150
}
```

---

## 9. Assumptions

1. The user has a running Athena Core API server accessible on their local network or internet
2. The user knows their server's IP/hostname and API key
3. The Flutter app does not need to manage the server itself (no server control)
4. A single app can connect to one server at a time (no multi-server management in v1.0)
