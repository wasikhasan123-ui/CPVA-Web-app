# CPVA App — Complete Project Overview

## What It Is
**CPVA (Chattogram Private Veterinary Association)** membership management web app.
- Flutter Web app deployed via Vercel
- Firebase (Spark plan): Firestore + Auth + FCM
- Branch pattern: `source-code` = Flutter source, `master` = build output

## Tech Stack
| Layer | Choice |
|---|---|
| Framework | Flutter Web (Material3, light-only) |
| State | flutter_bloc 8.1.6 |
| Routing | go_router 14.2.7 |
| DI | get_it 7.7.0 |
| Backend | Firebase Firestore + Auth + FCM |
| Images | ImgBB free API (fallback key: `0ff82139c3cde492b95e79208da506fa`) |
| Localization | flutter_localizations, ARB (English + Bengali, 60+ keys) |
| Fonts | Poppins + Noto Sans Bengali |
| Auth | Custom SHA-256 password for members (SharedPreferences), Firebase Auth for admin |
| ID Card | Client-side QR code + PDF |

## Theme (`lib/core/theme/app_colors.dart`)
- **Primary:** `#2E7D32` (green)
- **Primary Dark:** `#1B5E20`
- **Secondary:** `#4CAF50`
- **Background:** `#F5F7FA`
- **Surface:** `#FFFFFF`
- **Text Primary:** `#1D1B20`
- **Text Secondary:** `#666666`
- **Text Hint:** `#999999`
- **Border:** `#E0E0E0`
- **Success:** `#2E7D32`
- **Error:** `#D32F2F`
- **Card Gradient:** `[primaryDark, primary]`
- `withValues(alpha:)` used for opacity, NOT `withOpacity()`

## Architecture
```
lib/
  core/
    di/injection.dart          — GetIt registrations (all singletons)
    theme/app_colors.dart      — color palette
    theme/app_theme.dart       — ThemeData
    constants/app_constants.dart
    constants/app_strings.dart
    router/app_router.dart     — GoRouter routes
    utils/drive_url_helper.dart
  domain/
    entities/                  — MemberEntity, EventEntity, NoticeEntity, NewsEntity, GalleryEntity, ContactEntity
    repositories/              — AuthRepository, MemberRepository, ContentRepository (interfaces)
  data/
    models/                    — MemberModel, ExecutiveMemberModel, PaymentSubmission
    datasources/
      remote/
        firestore_service.dart — Firestore wrapper (setDocument, updateDocument, deleteDocument, collectionStream, queryWhere, getCollection, addDocument)
        remote_content_datasource.dart  — generic Firestore CRUD with seeding
        password_service.dart
      member_remote_datasource.dart
      registration_remote_datasource.dart
      payment_remote_datasource.dart
      imgbb_service.dart       — upload to ImgBB, SharedPreferences key storage
      photo_service.dart       — image picker + file save
      member_photo_cache.dart
      local_content_service.dart  — local JSON + SharedPreferences
      executive_local_datasource.dart
      email_service.dart
    repositories/              — AuthRepositoryImpl, MemberRepositoryImpl, ContentRepositoryImpl
  presentation/
    blocs/
      auth/ (bloc, state, event)
      member/ (bloc, state, event)
    widgets/
      section_state.dart       — LoadingState, EmptyState(icon, title, subtitle), ErrorState(message, onRetry)
      member_avatar.dart       — MemberAvatar with photo caching
      photo_avatar.dart
    pages/
      auth/     — login_page, forgot_password_page, change_password_page
      home/     — home_tab_page, home_page
      member/   — member_directory_page, member_details_page
      members/  — members_tab_page
      profile/  — profile_tab_page, my_profile_page
      registration/ — registration_page
      payment/  — payments_page
      id_card/  — id_card_page
      notices/  — notices_tab_page, notice_details_page
      events/   — events_tab_page, event_details_page
      news/     — news_page
      gallery/  — gallery_page
      contact/  — contact_page
      executive/— executive_members_page
      splash/   — splash_page
      admin/    — admin_panel_page, admin_dashboard_tab, admin_payments_tab, edit_* pages
```

## DI Registrations (`lib/core/di/injection.dart`)
```dart
sl<FirestoreService>()
sl<MemberRemoteDataSource>()          -> FirestoreService
sl<RegistrationRemoteDataSource>()    -> FirestoreService
sl<PaymentRemoteDataSource>()         -> FirestoreService
sl<PasswordService>()
sl<AuthRepository>()                  -> MemberRemoteDataSource + RegistrationRemoteDataSource + PasswordService
sl<RemoteContentDataSource>(instanceName: events/news/gallery/notices/contacts)
sl<MemberRepository>()                -> MemberRemoteDataSource
sl<ContentRepository>()              -> LocalContentService + all 5 RemoteContentDataSources
sl<PhotoService>(instanceName: member/executive)
sl<MemberPhotoCache>()
sl<ExecutiveLocalDataSource>()
sl<EmailService>()
sl<ImgbbService>()
```

## Key Business Rules
- **Members:** Authenticated via custom SHA-256 hash stored in SharedPreferences + Firebase Auth fallback for admin
- **Admin:** Mobile `01853548853`, default password `cpva2026`
- **Member object:** Has `authUid` field (used in payments for Firestore security)
- **Registrations:** Stored in Firestore `registrations` collection with `authUid`
- **Payments:** `01813059794`, amount `500` BDT, stored in Firestore `payments` collection
- **Images:** Uploaded to ImgBB (not Firebase Storage). URL stored in Firestore only.
- **Data seeding:** Local JSON assets in `assets/data/*.json` → SharedPreferences on mobile, Firestore on web (with idempotent seeding flags)
- **Mobile normalization:** Strip non-digits, `+880`/`880` → `0` prefix
- **Profile photos:** Custom pick/camera upload via `PhotoService`, cached in `MemberPhotoCache`

## Firestore Collections & Rules
| Collection | Create | Read | Update/Delete |
|---|---|---|---|
| `admins/{uid}` | false | admin or owner | false |
| `members/*` | admin | emailVerified | admin |
| `registrations/*` | signedIn (authUid==uid) | admin or owner | admin |
| `notices/*` | admin | emailVerified | admin |
| `contacts/*` | admin | emailVerified | admin |
| `events/*` | admin | emailVerified | admin |
| `news/*` | admin | emailVerified | admin |
| `gallery/*` | admin | emailVerified | admin |
| `payments/*` | emailVerified + `memberAuthUid==uid` | admin or owner | admin |
| `passwords/*` | false | false | false |
| default (catch-all) | false | false | false |

## Payment Workflow
1. User selects payment method (bKash/Nagad/Rocket)
2. User optionally uploads screenshot via ImgBB
3. User optionally enters transaction ID
4. At least one proof required (txId or screenshot)
5. `PaymentSubmission` created in Firestore with `status: 'pending'`
6. Admin sees it in Admin Panel → Payments tab
7. Admin can Approve (status → `approved`) or Reject (with reason, status → `rejected`)
8. Admin can Delete reviewed records (approved/rejected)
9. User sees live status on Payments page via `streamPaymentsForUser`

## Pulling Screenshots
- `ImgbbService.pickAndUpload()` — opens gallery picker, uploads to ImgBB, returns URL
- `ImgbbService.uploadBytes(Uint8List bytes, String filename)` — direct upload
- Fallback API key: `0ff82139c3cde492b95e79208da506fa`

## OpenCode Instructions for AI
When starting a new session:
1. Read `CPVA_PROJECT_OVERVIEW.md` for full context
2. Read any specific file(s) you need to modify before editing
3. Run `flutter analyze` after changes
4. Run `flutter build web --release` before deploy
5. Commit to `source-code`, then copy `build/web/*` to root on `master` for deploy
6. Keep `firestore.rules` updated in source-code but do NOT deploy rules automatically
7. Use `withValues(alpha:)` NEVER `withOpacity()`
8. Never store image bytes/base64 in Firestore
9. Do not modify: Firebase Auth login, registration approval, CSV import, member directory
