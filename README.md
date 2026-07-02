# FitTrack — Flutter Workout Tracker (Step 1: Onboarding + Auth)

## What's included so far
- `lib/theme/app_theme.dart` — shared colors & text styles
- `lib/widgets/custom_text_field.dart`, `custom_button.dart` — reusable UI
- `lib/services/auth_service.dart` — Firebase Auth + Firestore user profile
- `lib/screens/onboarding_screen.dart` — swipeable intro (3 pages)
- `lib/screens/auth/login_screen.dart` — email/password login
- `lib/screens/auth/signup_screen.dart` — email/password signup
- `lib/screens/home_placeholder_screen.dart` — temporary post-login screen
- `lib/main.dart` — app entry point + auth-based routing (`AuthGate`)

## Setup

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Connect Firebase** (required before running)
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart`, which `main.dart` imports.
   In the Firebase Console, enable **Authentication → Email/Password**
   and create a **Firestore Database** (test mode is fine while developing).

3. **Run the app**
   ```bash
   flutter run
   ```

## Flow
`AuthGate` in `main.dart` decides the first screen:
- Logged in → Home (placeholder for now)
- Not logged in, onboarding already seen → Login
- First launch → Onboarding → Login/Signup

## Next steps (coming in following messages)
- Home Dashboard (today's summary, streak, quick-start)
- Workout List + Workout Detail (log sets/reps)
- Exercise Library
- Progress/Charts page
- Profile/Settings page
