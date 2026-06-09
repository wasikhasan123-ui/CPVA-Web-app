# CPVA App — Complete Project Overview

## What It Is
**CPVA (Chattogram Private Veterinary Association)** membership management web app.

- Flutter Web app deployed via Vercel
- Firebase (Spark plan): Firestore + Auth + FCM
- Branch pattern: `source-code` = Flutter source, `master` = build output

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter Web (Material3, light-only) |
| State | flutter_bloc 8.1.6 |
| Routing | go_router 14.2.7 |
| DI | get_it 7.7.0 |
| Backend | Firebase Firestore + Auth + FCM |
| Images | ImgBB free API (fallback key in imgbb_service.dart) |
| Localization | flutter_localizations, ARB (English + Bengali) |
| Fonts | Poppins + Noto Sans Bengali |
| Auth | Firebase Auth (email/password) for all users |
| ID Card | Client-side QR code + PDF |

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
        firestore_service.dart — Firestore wrapper (setDocument, updateDocument, deleteDocument, getDocument, collectionStream, queryWhere, getCollection, addDocument)
        remote_content_datasource.dart  — generic Firestore CRUD with seeding (seedFromJson catches errors for non-admin)
        password_service.dart  — DEAD CODE (rules block all access to passwords collection)
      member_remote_datasource.dart
      registration_remote_datasource.dart
      payment_remote_datasource.dart
      imgbb_service.dart       — upload to ImgBB
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
      section_state.dart       — LoadingState, EmptyState, ErrorState
      member_avatar.dart
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
      notices/  — notices_tab_page (StreamBuilder), notice_details_page
      events/   — events_tab_page (StreamBuilder), event_details_page
      news/     — news_page (StreamBuilder)
      gallery/  — gallery_page (StreamBuilder)
      contact/  — contact_page (StreamBuilder)
      executive/— executive_members_page
      splash/   — splash_page
      admin/    — admin_panel_page, admin_dashboard_tab, admin_payments_tab, edit_* pages
```

## DI Registrations (`lib/core/di/injection.dart`)

```
sl<FirestoreService>()
sl<MemberRemoteDataSource>()          -> FirestoreService
sl<RegistrationRemoteDataSource>()    -> FirestoreService
sl<PaymentRemoteDataSource>()         -> FirestoreService
sl<PasswordService>()
sl<AuthRepository>()                  -> MemberRemoteDataSource + RegistrationRemoteDataSource + PasswordService + FirestoreService
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

- **Members:** Authenticated via Firebase Auth (email + password)
- **Admin:** Mobile `01853548853`, has doc in `admins/{uid}` collection
- **Admin detection (client):** `MemberEntity.isAdmin` checks `mobileClean == '01853548853'`
- **Admin detection (rules):** `isAdmin()` checks `exists(admins/{uid})` — this is the real security gate
- **Member object:** Has `authUid` field linking to Firebase Auth UID
- **Login flow (mobile):** Mobile → lookup `memberIndex/{mobile}` (public, no auth needed) → get email → `signInWithEmailAndPassword(email, password)`
- **Login flow (email):** Direct `signInWithEmailAndPassword`
- **getCurrentUser():** Checks `_firebaseAuth.currentUser` only. NO legacy SharedPreferences fallback.
- **Registrations:** User creates Firebase Auth account + submits to `registrations` collection. Admin approves → creates `members/{mobile}` doc + `memberAuth/{uid}` doc + `memberIndex/{mobile}` doc
- **Payments:** `01813059794`, amount `500` BDT, stored in Firestore `payments` collection
- **Images:** Uploaded to ImgBB (not Firebase Storage). URL stored in Firestore only.
- **Data seeding:** Local JSON assets in `assets/data/*.json`. `seedFromJson` catches permission errors for non-admin users — seeding only works for admin.
- **Firestore persistence:** DISABLED on web (`persistenceEnabled: false` in main.dart). All reads go to server.
- **Content pages:** ALL use real-time `StreamBuilder` + `streamAll()` (events, news, gallery, notices, contacts)

## Firestore Collections & Rules

| Collection | Document ID | Create | Read | Update/Delete |
|------------|-------------|--------|------|---------------|
| `admins/{uid}` | Firebase Auth UID | false | admin or owner | false |
| `members/{id}` | Mobile number or sequential (1-34) | admin | isApprovedMember or admin | admin |
| `memberAuth/{uid}` | Firebase Auth UID | admin | admin or owner | admin |
| `memberIndex/{mobile}` | Mobile number (digits only) | admin | **public (anyone)** | admin |
| `registrations/*` | APP-timestamp | signedIn (authUid==uid) | admin or owner | admin |
| `notices/*` | ID | admin | isApprovedMember or admin | admin |
| `contacts/*` | ID | admin | isApprovedMember or admin | admin |
| `events/*` | ID | admin | isApprovedMember or admin | admin |
| `news/*` | ID | admin | isApprovedMember or admin | admin |
| `gallery/*` | ID | admin | isApprovedMember or admin | admin |
| `payments/*` | PAY-timestamp | approvedMember (own uid) | admin or owner | admin |
| `passwords/*` | — | false | false | false (dead) |

### Key rule functions:
- `signedIn()` = `request.auth != null`
- `emailVerified()` = `signedIn() && request.auth.token.email_verified == true`
- `isAdmin()` = `signedIn() && exists(admins/{uid})`
- `isApprovedMember()` = `emailVerified() && exists(memberAuth/{uid})`
- `memberIndex` is publicly readable (`allow read: if true`) — needed for mobile login before auth

## Admin Panel Settings (one-time maintenance tools)

- **Rebuild Member Index** — populates `memberIndex/{mobile} = {email}` for all members. Needed after migration or bulk import. Safe to run anytime.
- **Rebuild Member Auth** — populates `memberAuth/{uid}` for all members with `authUid`. Required for members to pass `isApprovedMember()` rule. Safe to run anytime.
- **Fix Mobile Numbers** — normalizes +880 → 01 format
- **ImgBB API Key** — configure image upload key
- **Import from Spreadsheet** — CSV bulk member import
- **Restore Original Members** — re-seeds from bundled JSON (destructive)

## Payment Workflow

1. User selects payment method (bKash/Nagad/Rocket)
2. User optionally uploads screenshot via ImgBB
3. User optionally enters transaction ID
4. At least one proof required (txId or screenshot)
5. `PaymentSubmission` created in Firestore with `status: 'pending'`
6. Admin sees it in Admin Panel → Payments tab
7. Admin can Approve or Reject (with reason)
8. User sees live status via `streamPaymentsForUser`

## Registration Flow

1. User fills registration form + creates Firebase Auth account (`createUserWithEmailAndPassword`)
2. Verification email sent (`sendEmailVerification`)
3. Registration doc saved to Firestore `registrations` collection (authUid, status=pending, password='')
4. User verifies email by clicking link
5. Admin approves in Admin Panel → creates `members/{mobile}` + `memberAuth/{uid}` + `memberIndex/{mobile}`
6. User can now log in with mobile or email

## Common Issues & Fixes

| Problem | Cause | Fix |
|---------|-------|-----|
| Member can't log in with mobile | Not in `memberIndex` | Admin Panel → Rebuild Member Index |
| Member logged in but can't see content | No `memberAuth/{uid}` doc | Admin Panel → Rebuild Member Auth |
| "Account not found" after correct password | Member not in Firestore `members` collection, or `authUid` field empty | Check member doc has correct `authUid` matching Firebase Auth UID |
| Content tabs show "Could not load" | `memberAuth` collection missing or user not in it | Rebuild Member Auth |
| Admin-added member can't log in | EditMemberPage doesn't create `memberAuth` or `memberIndex` | Run both Rebuild buttons, and ensure member has Firebase Auth account |

## OpenCode Instructions for AI

When starting a new session:

1. Read `CPVA_PROJECT_OVERVIEW.md` for full context
2. Read any specific file(s) you need to modify before editing
3. Run `flutter analyze` after changes
4. Run `flutter build web --release` before deploy
5. Commit to `source-code`, then copy `build/web/*` to root on `master` for deploy
6. Keep `firestore.rules` updated in source-code — deploy rules separately with `firebase deploy --only firestore:rules` or via Firebase Console → Firestore → Rules
7. Use `withValues(alpha:)` NEVER `withOpacity()`
8. Never store image bytes/base64 in Firestore
9. When admin creates/approves a member, always write to ALL THREE: `members/{id}`, `memberAuth/{uid}`, `memberIndex/{mobile}`
10. All content pages use `StreamBuilder` + `stream*()` methods — NOT `FutureBuilder`
11. Firestore persistence is DISABLED on web — do not re-enable it
12. `getCurrentUser()` must only use Firebase Auth — NO SharedPreferences fallback
13. `seedFromJson()` must catch errors silently for non-admin users
14. `deleteNews/deleteEvent/deleteNotice/deleteContact/deleteGallery` all use `deleteWhere()` pattern
