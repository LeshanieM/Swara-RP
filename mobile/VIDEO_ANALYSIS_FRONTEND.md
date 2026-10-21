# Component 2 - Secondary behaviours at stutter moments

The Component 2 flow sends one video of the child to the Swara API (`/api/c2`). The API takes the stutter moments from the video's own audio track: it creates a linked C1 assessment. At each stutter moment it then checks whether the face (FG: eye, lip, jaw, cheek) or the head (HM) moved unusually compared with the child's own fluent speech. The result is a research estimate, not a diagnosis.

**Workflow:** Select one video -> parent consent (parent PIN) -> Processing -> Results.

| Route | Screen |
|---|---|
| `/c2/video/upload` | Select and preview one video, give parent consent, start the analysis, or open a previous analysis |
| `/c2/video/process/:id` | Poll the analysis: video received → finding stutter moments → face and head movement |
| `/c2/video/results/:id` | FG / HM summary, deviation per signal at stutter moments, each moment with its explanation, tracking details |

Code: `lib/features/concomitant/{data/models,data/providers,presentation}` (`video_*`). The models follow `server/contracts/c2/analyze-video.response.example.json`, and `test/video_analysis_models_test.dart` parses that file.

## Run

```bash
cd mobile && flutter pub get
# server: MongoDB, the speech (8010) and vision (8011) services and the API (5001); see server/README.md
flutter run
flutter run --dart-define=API_HOST=192.168.1.20
flutter run --dart-define=API_BASE_URL=https://host
```

Log in with a registered account. Demo mode has no server session, so this flow shows a sign-in message there.

## Request

- The upload is a parent upload (`inputPath=parent_upload`) for the active child: the child account itself, or the child a therapist opened. It sends `childId`, `age`, `videoConsent=true` and `language=si`.
- The API accepts it only with parent mode on (`X-Parent-Token`). Therapists don't need the PIN.
- Ages 11–14 do C1's reading task, so the app also sends the Sinhala reading passage (`passageId`). The child should be reading that passage in the video.
- Formats: mp4, mov, m4v, webm, avi, mkv; up to 200 MB; 2 s to 3 min; one face, filmed from the front.

## Result interpretation

- Each signal's deviation is in standard deviations from the child's own fluent speech. A moment counts as FG or HM only when a signal goes past its threshold for long enough.
- `Could not be assessed` means no moment had enough visible face. It is never "no behaviour".
- Warnings such as `low_face_coverage` or `insufficient_fluent_baseline` are listed under Tracking.
- Web supports video upload; local video preview is unavailable in the browser.
- Android local-server HTTP access is enabled in the manifest. Use HTTPS for production deployments.
