# SWARA Component 3 camera engagement

This integration adds a small live front-camera preview during an active Component 3 activity. The project already had the camera pipeline: the parent can opt in from the Component 3 home screen, Flutter reads frames locally with ML Kit, and only 10-second numeric feature windows are sent with the normal activity result. This change exposes the already-running camera controller in the therapy UI; it does not add frame or video uploads.

## What Component 3 does

Component 3 is the adaptive therapy session mounted at `/c3/forest-therapy`. The server selects the next activity with its Hybrid LinUCB recommender. The mobile app starts a session, requests each activity, records activity signals, and posts the result. The server combines activity logs with camera-derived estimates when usable camera windows are available. If the camera is off, unavailable, or sees no face, scoring falls back to activity logs.

| Mobile action | Server request |
| --- | --- |
| Start or resume therapy | `POST /api/c3/sessions` with `childId`, `age`, `language`, and `cameraOn` |
| Request next activity | `POST /api/c3/sessions/:id/next-activity` |
| Submit activity result | `POST /api/c3/sessions/:id/activities/:attemptId/result`, including `camera.windows` when available |
| Finish the session | `POST /api/c3/sessions/:id/complete` |

`mobile/lib/core/network/api_client.dart` supplies the configured base URL and bearer/parent tokens. `mobile/lib/features/therapy/therapy_api_service.dart` maps the C3 calls. The camera sends per-window `facePresentRatio`, head movement, eye-open/closed, and smile summary features; it never sends an image.

## Consent and privacy behavior

- Camera engagement is off by default. Enable it from the Component 3 home screen with the parent-mode control.
- Android and iOS request camera access when an activity begins. The preview and “Camera on” badge are visible while monitoring is active.`r`n- On Flutter web, the parent can enable a webcam preview; browser frames are not sent through ML Kit, so engagement scoring uses activity logs only. Use HTTPS or localhost so the browser grants camera access.
- Frames are processed on-device. Only feature summaries are included in the activity result; no frame or video is stored or uploaded by the engagement camera.
- The camera stops at the end of an activity and has a 10-minute safety limit. If camera access is unavailable, the activity can continue with log-based scoring.
- Camera monitoring with children requires the project’s applicable ethics approval and parent consent before pilot use.

## Run the mobile app and server

1. Configure the API URL when launching the app. The defaults are `10.0.2.2:5001` for Android emulators and `localhost:5001` for iOS simulator/web. For a physical phone use `flutter run --dart-define=API_HOST=<computer-LAN-IP>`; for a deployed server use `flutter run --dart-define=API_BASE_URL=https://<your-api-host>`.
2. Start MongoDB from `server/` with `docker compose up -d`.
3. Configure `server/api/.env` from `server/.env.example`, then start the API using the commands in `server/README.md`. Start the vision service only if needed by the rest of the project; Component 3 camera scoring runs in the API and does not upload camera frames to that service.
4. From `mobile/`, run `flutter pub get` and `flutter run` on an Android or iOS device or emulator. Grant the camera permission when prompted, enable the parent camera setting, and start an activity to see the preview.

## DAiSEE training path

The checked-in model at `server/api/src/modules/c3/data/engagementCameraModel.json` is explicitly marked `provisional: true`; its hand-set weights are not a trained model. DAiSEE training support already exists in `server/vision-service/training/build_engagement.py` and `train_engagement.py`.

After obtaining DAiSEE under its research-use terms and placing it outside the repository, create the 10-second feature dataset and train/evaluate a candidate model from `server/vision-service/`:

```bash
python -m training.build_engagement --daisee /path/to/DAiSEE --out data/daisee_engagement.npz --workers 6
python -m training.train_engagement --data data/daisee_engagement.npz
```

The trainer compares models using subject-grouped validation and the official test split, writes the selected model to `server/api/src/modules/c3/data/engagementCameraModel.json`, and creates a training report. Restart the API after training and inspect `GET /api/c3/engagement/model` (authenticated) for `provisional: false`. Keep the DAiSEE videos, extracted data, and model artifacts private and outside version control until reviewed. DAiSEE contains lecture learners, so its scores need separate validation on the intended child therapy population; a trained DAiSEE model is not evidence of clinical validity.

## Verification

The repo’s existing focused tests are `mobile/test/camera_features_test.dart` and `mobile/test/api_adapters_test.dart`. The camera feature test checks the phone’s feature calculation against the server contract at `server/contracts/c3/engagement-camera-features.example.json`. Run them from `mobile/` with:

```bash
flutter test test/camera_features_test.dart test/api_adapters_test.dart
```

Also confirm the live camera preview on a device with a front camera; an emulator build alone cannot verify camera permission or actual preview rendering.
