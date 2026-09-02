# Swara: A Sinhala-Based Intelligent Framework for Supporting Children with Stuttering

This repository contains the source code for the **Swara Research Prototype**, developed as a final-year IT research project. 

> **⚠️ RESEARCH PROTOTYPE DISCLAIMER**
> This application is a research prototype developed to demonstrate the feasibility and integration of the proposed Swara framework. The current prototype uses synthetic/sample data and preliminary AI/rule-based processing. It is not a clinically validated diagnostic or treatment system. Real participant data, therapist validation, ethical approval, model training, and empirical evaluation are required before any clinical use.

## Project Overview

Swara is a comprehensive, multi-component research prototype designed to assist children with stuttering, their parents, and Speech and Language Pathologists (SLPs). The application is built entirely using the **Impilo Design System**—a gentle, non-clinical design language featuring a core Navy Blue (`#000080`) scaffold, warm linen backgrounds (`#F4F0E8`), and targeted pastel accent tokens. This aesthetic ensures a child-friendly, highly engaging, and anxiety-reducing user experience, moving away from traditional "clinical" applications.

## The Four Research Components

The Swara framework is driven by four integrated pillars:

### Component 1: Speech Stuttering Detection & Assessment
A multi-step, localized (Sinhala/English) assessment workflow that automatically adapts based on age demographics (4–7 years: Picture Description; 7–15 years: Reading Task). It features a robust recording interface, mock-driven AI processing animations, and an intuitive SLP dashboard to visualize stuttering severity and disfluency types.

### Component 2: Secondary Behaviors Associated with Stuttering
A "gentle observation" module for analyzing physical stuttering characteristics (e.g., facial tension, eye blinking) via video upload or live recording. The workflow emphasizes supportive, non-clinical messaging to track physical behaviors without intimidating the child, utilizing a customized lavender/pastel component theme.

### Component 3: Adaptive Speech Therapy Activities
An interactive and gamified speech therapy module featuring customized breathing exercises, storytelling sessions, and adaptive challenges. The interface is highly immersive, utilizing continuous visual feedback to motivate regular practice.

### Component 4: Personalized Communication Challenge (Generalization)
A research-driven, personalized speech elicitation framework designed to assess real-world communication progress. Instead of manual selection, it automatically assigns speech tasks based on the child's session history, ensuring longitudinal consistency for research metrics while keeping the child-facing interface positive and pressure-free.

## Architecture & Technology Stack

The Swara framework consists of three main components:

1.  **Mobile Frontend (Flutter):** A child-friendly mobile application. It relies on `AppTheme` for unified tokens, `GoRouter` for shell navigation, and `Riverpod` for state management.
2.  **Backend API (Node.js/Express):** REST API handling business logic, authentication, database interaction (MongoDB), and proxying AI requests.
3.  **AI Service (Python/FastAPI):** A dedicated service intended to handle ML models, feature extraction (e.g., using LibROSA), and NLP tasks.

**Tech Stack:**
*   **Mobile App:** Flutter, Dart, Riverpod, GoRouter, Google Fonts (Nunito)
*   **Backend:** Node.js, Express, MongoDB, Mongoose, JWT
*   **AI Service:** Python, FastAPI, LibROSA, Scikit-learn (planned)

## Demo Mode

The Flutter application includes a fully functional **Demo Mode**, which can be toggled on the login screen. When Demo Mode is active, the app uses localized synthetic data (avoiding network calls) and seamlessly demonstrates the UI, animations, and user flows without requiring the backend or AI service to be running.

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
# Or test locally in the browser
flutter run -d chrome
```

## Future ML Integration

The architecture is designed to allow the research team to incrementally replace prototype logic with trained ML models:
*   Replace mock endpoints in `ai-service/app/main.py` with actual model inference code.
*   Integrate trained models for stutter detection (Component 1) and communication assessment (Component 4) seamlessly, without modifying the mobile app UI.
