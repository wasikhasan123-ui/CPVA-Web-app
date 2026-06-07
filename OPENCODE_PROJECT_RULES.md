# CPVA App - OpenCode Project Rules

## 1. Project Type

This is a Flutter app for CPVA - Chattogram Private Veterinary Association.

Main stack:
- Flutter / Dart
- Flutter Web deployment
- Firebase / Firestore
- SharedPreferences
- GoRouter
- flutter_bloc
- get_it service locator
- fl_chart
- pdf / printing

Main source branch:
- source-code

Deployment branch/build:
- master or deployed web output

## 2. Most Important Rule

Do not rewrite large files unnecessarily.

Prefer small, targeted changes.

Before changing code:
1. Identify the exact file.
2. Identify the exact method/widget.
3. Explain what will change.
4. Change only that part.

Do not change unrelated features.

## 3. Branch Rules

When making source changes:
- Push source changes to `source-code`
- Deploy built web output to `master` only if requested
- Do not lose source code
- Do not replace source branch with build output

## 4. Files to Be Extra Careful With

Be very careful with:

```txt
lib/data/datasources/member_remote_datasource.dart
lib/data/repositories/auth_repository_impl.dart
lib/presentation/pages/admin/admin_panel_page.dart
lib/presentation/pages/id_card/id_card_page.dart
lib/core/routes/app_router.dart
assets/data/members.json
web/index.html
web/firebase-messaging-sw.js
```

These files affect login, member data, admin recovery, digital ID, and deployment.

## 5. Member Data Rules

Member identity is based mainly on cleaned mobile number.

Always clean mobile numbers using Bangladesh-safe logic:

```dart
String cleanMobile(String raw) {
  String v = raw.trim().replaceAll(RegExp(r'[^\d+]'), '');

  if (v.startsWith('+880')) {
    v = '0${v.substring(4)}';
  } else if (v.startsWith('880') && v.length > 10) {
    v = '0${v.substring(3)}';
  }

  v = v.replaceAll(RegExp(r'[^\d]'), '');

  if (v.length == 10 && !v.startsWith('0')) {
    v = '0$v';
  }

  return v;
}
```

Never create duplicate members if the cleaned mobile number already exists.

Do not overwrite existing members during CSV import unless explicitly requested.

Do not delete all members unless a backup/restore plan exists.

## 6. CSV Import Rules

CSV import must:
- support quoted commas
- support multiline quoted fields
- not use `line.split(',')`
- not use `LineSplitter().convert(content)` for row parsing
- parse the full CSV content
- skip existing members
- not overwrite existing member photos
- convert Google Drive photo URLs into direct image URLs
- ignore local filename-only photo values
- use `sl<MemberRemoteDataSource>().saveMember(member)`

CSV import must be additive-only by default.

If asked to import a CSV:
1. Check how many rows are new.
2. Check how many are existing.
3. Import only new members unless explicitly told otherwise.

## 7. Restore Original Members Rule

The app has an emergency restore feature:

```dart
sl<MemberRemoteDataSource>().resetAdminChanges();
```

This restores original members from:

```txt
assets/data/members.json
```

Do not remove this feature.

It is needed to recover from bad imports.

## 8. Login Emergency Repair Rule

`MemberRemoteDataSource.getAllMembers()` may auto-mix original bundled members from:

```txt
assets/data/members.json
```

This is intentional.

Do not remove this unless a safer migration/backup system is added.

It helps login work if Firestore `members` collection is broken or empty.

## 9. Profile Photo Rules

Existing profile photos are important.

Do not replace `photoUrl` with:
- empty string
- local filename
- invalid URL

Only save photo URL if it starts with:

```txt
http://
https://
```

For Google Drive links, convert:

```txt
https://drive.google.com/open?id=FILE_ID
```

to:

```txt
https://lh3.googleusercontent.com/d/FILE_ID
```

## 10. Admin Panel Rules

Admin Panel currently has:

```txt
Dashboard
Pending
Processed
Settings
```

Do not remove existing tabs.

Do not duplicate the same feature in multiple places.

If adding a new admin feature:
- put dashboard/stat widgets in admin widgets/services when possible
- keep `admin_panel_page.dart` small
- avoid making `admin_panel_page.dart` huge again

Recommended structure:

```txt
lib/presentation/pages/admin/
├── admin_panel_page.dart
├── services/
│   └── member_csv_importer.dart
└── widgets/
    └── admin_dashboard_tab.dart
```

## 11. Digital ID Rules

Digital ID card download uses:
- RepaintBoundary
- pdf
- printing

Do not redesign the ID card unless explicitly requested.

If modifying download:
- keep front and back side PDF export
- make sure profile image has time to load before capture
- do not break normal card preview

## 12. Authentication Rules

Be careful with:

```txt
lib/data/repositories/auth_repository_impl.dart
```

Known behavior:
- member default password may be `cpva2026`
- admin fallback password may be `admin`
- login uses mobile lookup through member data

Do not break login while changing member data.

If changing auth, test:
1. admin login
2. member login
3. logout
4. password reset/change password

## 13. Firestore Rules

Firestore collections currently used include:

```txt
members
registrations
passwords
events
news
gallery
```

Do not rename collections unless explicitly requested.

When saving members, use:

```dart
sl<MemberRemoteDataSource>().saveMember(member)
```

unless there is a specific reason to use Firestore directly.

## 14. UI Rules

Keep UI consistent with:

```dart
AppColors
AppTheme
BengaliText
```

Do not introduce random colors/styles unless needed.

Do not redesign existing pages unless requested.

## 15. Before Deploying

Always run:

```bash
flutter analyze
flutter build web
```

If errors happen:
- fix compile errors only
- do not rewrite unrelated code

## 16. After Deploying

Report:
- source-code commit hash
- master/deployment commit hash
- files changed
- summary of changes
- any warnings/errors
- what user should test

## 17. Safety Checklist Before Member/Data Changes

Before any member import/delete/reset:
- Is this additive or destructive?
- Could this overwrite photos?
- Could this create duplicates?
- Is mobile number cleaned?
- Is there a restore path?
- Is `assets/data/members.json` still intact?
- Is admin login still possible?

If unsure, ask before proceeding.

## 18. Preferred Change Style

Prefer:
- extracting services/widgets
- small focused methods
- clear helper functions
- preserving behavior

Avoid:
- large rewrites
- changing many files at once
- changing auth and data logic together
- deleting recovery tools
- deleting old working code without replacement
