# CPVA App — Chattogram Private Veterinary Association

A Progressive Web App (PWA) member portal for the Chattogram Private Veterinary Association.
Built with Flutter, deployed to Vercel.

## Live App
https://project-f6uaz-rhbzxvffu-judgemental-person-s-projects.vercel.app

## Architecture
- **Flutter 3.12+** (Dart) with **BLoC** state management
- **Firebase**: Firestore (no Blaze — Spark plan only), FCM, Cloud Messaging
- **Routing**: go_router
- **DI**: get_it
- **PWA**: deployed as static build to Vercel

## Project Structure
```
lib/
  core/            # constants, theme, DI, routes, errors, utils
  domain/          # entities, repository interfaces
  data/            # models, datasources, repository impls
  presentation/    # BLoCs, pages, widgets
assets/
  data/            # bundled JSON seed (notices, events, news, contacts, executives, members, gallery)
  images/          # logos
web/               # PWA bootstrap, FCM service worker
android/           # bare Flutter Android shell
tool/              # one-off maintenance scripts
test/              # widget tests
```

## Running Locally
```bash
flutter pub get
flutter analyze
flutter run -d chrome
```

## Building for Production
```bash
flutter build web --release
# Then push the contents of build/web/ to the master branch of the GitHub repo
# Vercel auto-deploys from master.
```

## Secrets
The repository does **not** contain real secrets. Look for `[REDACTED_SECRET]` in:
- `lib/data/datasources/imgbb_service.dart` (Imgbb API key)
- `web/index.html` (Firebase VAPID key)

Firebase web config is committed as it is public by design. The Imgbb key and
VAPID key are redacted in this source-only branch; the real values are baked
into the live build that lives on the `master` branch.

## Default Credentials (for local testing)
- **Admin mobile**: `01853548853` — **password**: `(admin)` (literal parens)
- **Member default password**: `cpva2026`
- Approving an application from the admin panel sets the password the applicant
  chose on the registration form.

## Branch Layout
- `master` — Flutter web build output (deployed to Vercel automatically)
- `source-code` — original Flutter source code (this branch)
