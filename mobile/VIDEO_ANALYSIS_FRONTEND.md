# Component 2 - Temporal movement feature workflow

The Component 2 research flow is intentionally focused on extracting temporal movement features from one video. It does not generate a diagnosis or classify filled/unfilled gaps or head movements.

**Workflow:** Concomitant screen -> Research mode: temporal movement features -> Select one video -> Processing -> Feature results.

| Route | Screen |
|---|---|
| `/c2/video/upload` | Select and preview one video, start analysis, or open a previous analysis |
| `/c2/video/process/:id` | Poll analysis status and show progress |
| `/c2/video/results/:id` | Show TMMF feature summary, per-window values, and tracking details |

Code: `lib/features/concomitant/{data/models,data/providers,presentation}` (`video_*`).

## Run

```bash
cd mobile && flutter pub get
# backend: MongoDB + Node (5000) + FastAPI (8000) running
flutter run
flutter run --dart-define=API_HOST=192.168.1.20
flutter run --dart-define=API_BASE_URL=https://host
```

Log in with a registered account. Demo mode uses a fake token that the Node API rejects.

## Result interpretation

- The result screen presents MediaPipe-derived eye, lip, jaw, and head movement signals in temporal windows.
- Values are research features. They are not clinical conclusions, validated secondary-behavior labels, or FG/HM predictions.
- The old multi-technology comparison, timeline filters, annotated-video player, and ground-truth evaluation views were removed from this flow.
- Web supports video upload; local video preview is unavailable in the browser.
- Android local-backend HTTP access is configured in the manifest. Use HTTPS for production deployments.
