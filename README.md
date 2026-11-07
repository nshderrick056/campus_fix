# CampusFix: Campus Incident Reporting App

Students report campus issues (facilities, water, electricity, safety, ...) and staff
update their status. Built with Flutter (Android target), Firebase Auth, Cloud Firestore,
Cloudinary for photos, and BLoC/Cubit for state. See [PLAN.md](PLAN.md) for the full plan.

## Project structure

```
lib/
  config/        env.example.dart (copy to env.dart, git-ignored)
  core/          theme/ (colours, text styles, ThemeData), constants/, router/
  data/          repositories/, services/ (PhotoStorageService, ...)
  logic/         cubits + states
  models/        Incident, AppUser, enums
  presentation/  screens/, widgets/
```

## Theming

Light and dark themes (`AppTheme.light` / `AppTheme.dark`) follow the system setting.
Both palettes live in `lib/core/theme/app_colors.dart` as a `ThemeExtension`. In widgets,
read colours with `context.colors.primary` (never hard-coded hex), and text styles with
`Theme.of(context).textTheme`.

## Setup

### 1. Flutter

```bash
flutter pub get
```

### 2. Firebase (Auth + Firestore)

1. Create a Firebase project and enable **Authentication → Email/Password** and **Cloud Firestore**.
2. Install the CLIs and generate the config:

   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   flutterfire configure --platforms=android,ios
   ```

   This creates `lib/firebase_options.dart` and `android/app/google-services.json`
   (both git-ignored).
3. In `lib/main.dart`, follow the `TODO(firebase)` to call `Firebase.initializeApp`.

### 3. Cloudinary (photo storage)

Firebase Storage needs the paid Blaze plan, so photos go to Cloudinary (lecturer-approved).

1. Create a free Cloudinary account and note your **cloud name**.
2. Settings → Upload → add an **unsigned** upload preset. Limit it to the folder
   `campus_incidents/`, the formats jpg/png/webp, and a max size of about 5 MB.
3. Copy the env template and fill in your values:

   ```bash
   cp lib/config/env.example.dart lib/config/env.dart
   ```

   `env.dart` is git-ignored. Never put the Cloudinary API secret in the app.

### 4. Run

```bash
flutter run
```

## Checks

```bash
flutter analyze
flutter test
```
