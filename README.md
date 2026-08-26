# Swara: A Sinhala-Based Intelligent Framework for Supporting Children with Stuttering

This repository contains the source code for the **Swara Research Prototype**, developed as a final-year IT research project.

> **⚠️ RESEARCH PROTOTYPE DISCLAIMER**
> This application is a research prototype developed to demonstrate the feasibility and integration of the proposed Swara framework. The current prototype uses synthetic/sample data and preliminary AI/rule-based processing. It is not a clinically validated diagnostic or treatment system. Real participant data, therapist validation, ethical approval, model training, and empirical evaluation are required before any clinical use.

## Architecture

The Swara framework consists of three main components:

1.  **Mobile Frontend (Flutter):** A child-friendly, mobile application used by children, parents, and speech and language therapists.
2.  **Backend API (Node.js/Express):** REST API handling business logic, authentication, database interaction (MongoDB), and proxying AI requests.
3.  **AI Service (Python/FastAPI):** A dedicated service intended to handle ML models, feature extraction (e.g., using LibROSA), and NLP tasks. (Currently using prototype implementations).

## Technology Stack

*   **Mobile App:** Flutter, Dart, Riverpod, GoRouter, Dio
*   **Backend:** Node.js, Express, MongoDB, Mongoose, JWT
*   **AI Service:** Python, FastAPI, LibROSA, Scikit-learn (planned)

## Demo Mode

The Flutter application includes a fully functional **Demo Mode**. You can toggle this on the login screen. When Demo Mode is active, the app uses localized synthetic data and does not require the backend or AI service to be running. This is ideal for demonstrating the UI and user flows.

## Setup Instructions

### 1. Prerequisites
*   Flutter SDK (>=3.1.0)
*   Node.js (v18+)
*   Python (3.10+)
*   MongoDB (running locally or via Atlas)

### 2. Backend Setup
```bash
cd backend
npm install

# Create a .env file based on the provided .env defaults
# Start the server (runs on port 5000)
npm run dev

# (Optional) Seed the database with demo users/children
npm run seed
```

### 3. AI Service Setup
```bash
cd ai-service
pip install -r requirements.txt

# Run the FastAPI server (runs on port 8000)
uvicorn app.main:app --reload
```

### 4. Flutter Mobile App Setup
```bash
cd mobile
flutter pub get

# Run the application (connect an emulator or physical device)
flutter run
or
flutter run -d chrome
```

## Future ML Integration

The architecture is designed to allow the research team to incrementally replace prototype logic with trained ML models:
*   Replace mock endpoints in `ai-service/app/main.py` with actual model inference code.
*   Integrate trained models for stutter detection (Component 1) and communication assessment (Component 4) without modifying the mobile app or core backend logic.
