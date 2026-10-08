# Swara

Swara is a research prototype exploring digital tools to support children who stutter, their families, and speech-language professionals. It includes a Flutter mobile app, a Node.js API, and a Python service for speech and video analysis.

This is a prototype, not a clinically validated assessment or treatment system. Some analysis and demo flows use sample or simulated results.

## What’s in the repository

- `mobile/` — Flutter app
- `backend/` — Express API (default port `5000`)
- `ai-service/` — FastAPI service (default port `8000`)

The app can also be explored in Demo Mode without starting the backend or AI service.

## Requirements

- Flutter SDK (3.1 or newer) and a device, emulator, or Chrome
- Node.js 18 or newer
- Python 3.10 or newer
- MongoDB, if you need backend features that use the database

## Run the project

Open a separate terminal for each service. Run commands from the repository folder unless a `cd` command is shown.

### AI service

On Windows PowerShell:

```powershell
cd ai-service
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --reload --port 8000
```

On macOS or Linux:

```bash
cd ai-service
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --reload --port 8000
```

The API is available at `http://localhost:8000`; its interactive docs are at `http://localhost:8000/docs`.

If you already have a `venv` folder, you can activate it instead of creating `.venv`. Python virtual environments should be recreated if the project folder has been moved, since their launchers can retain the old path.

### Backend

```bash
cd backend
npm install
npm run dev
```

The API uses port `5000` by default. It connects to `mongodb://localhost:27017/swara_db` when MongoDB is available. Set `MONGODB_URI` in your local environment to use a different database. Do not commit credentials or private environment files.

### Mobile app

```bash
cd mobile
flutter pub get
flutter run
```

To run in Chrome, use `flutter run -d chrome`. For a connected phone or emulator, choose that device in Flutter.

## Notes

- The backend can start without MongoDB, but database-backed features will not be available.
- The AI service includes prototype analysis endpoints; results should not be treated as clinical findings.
- See `ai-service/VISION_README.md` for details on the video-analysis setup.
