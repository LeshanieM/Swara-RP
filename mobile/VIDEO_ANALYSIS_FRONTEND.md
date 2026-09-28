# Component 2 - Video analysis (Flutter)

Workflow: **Concomitant screen -> "Research mode" -> Video selection -> Processing -> Results ->
(Technology detail | Comparison | Timeline | Annotated video | Research metrics)**

| Route | Screen |
|---|---|
| `/c2/video/upload` | Select ONE video, preview, research options, Start Analysis, previous analyses |
| `/c2/video/process/:id` | Live status polling (every 2 s) |
| `/c2/video/results/:id` | Technology cards + links |
| `/c2/video/results/:id/tech/:tech` | One technology in detail |
| `/c2/video/results/:id/compare` | Support matrix, event/duration comparison, processing/tracking |
| `/c2/video/results/:id/timeline` | Dynamic event timeline (technology + behavior filters) |
| `/c2/video/results/:id/overlay` | Original vs annotated video |
| `/c2/video/results/:id/metrics` | Precision/recall/F1 vs ground truth (or "not provided") |

Code: `lib/features/concomitant/{data/models,data/providers,presentation}` (`video_*`).

## Run

```bash
cd mobile && flutter pub get            # installs the new video_player dependency
# backend: MongoDB + Node (5000) + FastAPI (8000) running
flutter run                             # Android emulator -> 10.0.2.2, iOS sim/web -> localhost
flutter run --dart-define=API_HOST=192.168.1.20        # physical device: your PC's LAN IP
flutter run --dart-define=API_BASE_URL=https://host    # or a full URL
```

Log in with a **real registered account**. Demo mode uses a fake token that Node rejects (the app says so).

## Notes
- Overlay videos: FastAPI now serves them (`GET /analyze-video/{id}/overlay/{tech}`, Range-capable) and Node
  proxies them (`GET /api/concomitant/video-analysis/:id/overlay/:tech`). Enable
  "Generate annotated video" under *Research options*; only MediaPipe produces one today.
- Ground truth: attach a JSON `{"annotations":[{"behavior","start_time","end_time"}]}` under *Research options*.
- Web: upload works; local video preview and the original-video player are native-only.
- Android manifest gained `INTERNET` + `usesCleartextTraffic` for the local HTTP backend (tighten for production).
- Tests: `flutter test test/video_analysis_models_test.dart`
