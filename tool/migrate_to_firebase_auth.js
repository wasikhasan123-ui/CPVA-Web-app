/**
 * Migration script: Migrate legacy password members to Firebase Auth.
 *
 * Usage:
 *   node tool/migrate_to_firebase_auth.js --dry-run [--service-account=path/to/key.json]
 *   node tool/migrate_to_firebase_auth.js --apply  [--service-account=path/to/key.json]
 *
 * Prerequisites:
 *   - GOOGLE_APPLICATION_CREDENTIALS env var OR --service-account=path/to/key.json
 *   - npm install firebase-admin
 *
 * Modes:
 *   --dry-run   Read members, validate, report what would happen. No mutations.
 *   --apply     Create Firebase Auth users, update Firestore docs, create admins/{uid}.
 *
 * Admin member: mobile 01853548853 (cleaned)
 *   - password: admin
 *   - admins/{uid} doc created with role, email, mobile, createdAt
 *
 * Normal members:
 *   - password: cpva2026
 *
 * Members without valid email: skipped with a warning (migration continues).
 * Existing authUid: reported but not overwritten unless re-migration forced.
 */

const { initializeApp, applicationDefault, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

// --- Parse CLI args ---
const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');
const isApply = args.includes('--apply');
const projectArg = args.find(a => a.startsWith('--project='));
const saArg = args.find(a => a.startsWith('--service-account='));
const projectId = projectArg ? projectArg.split('=')[1] : undefined;
const saPath = saArg ? saArg.split('=')[1] : undefined;

if (!isDryRun && !isApply) {
  console.error('ERROR: Specify --dry-run or --apply');
  process.exit(1);
}
if (isDryRun && isApply) {
  console.error('ERROR: Use either --dry-run or --apply, not both');
  process.exit(1);
}

// --- Init Firebase Admin ---
if (saPath) {
  const serviceAccount = require(saPath);
  initializeApp({ credential: cert(serviceAccount), projectId });
} else {
  initializeApp({ credential: applicationDefault(), projectId });
}

const auth = getAuth();
const db = getFirestore();

const ADMIN_MOBILE = '01853548853';
const ADMIN_PASSWORD = 'admin';
const MEMBER_PASSWORD = 'cpva2026';

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function cleanMobile(m) {
  return (m || '').replace(/[^\d]/g, '');
}

async function run() {
  const membersSnapshot = await db.collection('members').get();
  const totalMembers = membersSnapshot.size;

  let withValidEmail = 0;
  let withMissingEmail = 0;
  let wouldCreate = 0;
  let alreadyExists = 0;
  let adminMember = null;
  let adminEmail = null;
  let adminUid = null;
  let adminDocExists = false;

  const results = [];

  for (const doc of membersSnapshot.docs) {
    const data = doc.data();
    const email = (data.email || '').trim().toLowerCase();
    const mobile = cleanMobile(data.mobile || '');
    const existingAuthUid = data.authUid || '';
    const isAdmin = mobile === ADMIN_MOBILE;

    const entry = {
      docId: doc.id,
      docRef: doc.ref,
      name: data.name || '(no name)',
      email,
      mobile,
      isAdmin,
      hasEmail: EMAIL_RE.test(email),
      hasAuthUid: !!existingAuthUid,
      existingAuthUid: existingAuthUid || null,
      action: null,
    };

    if (!entry.hasEmail) {
      entry.action = 'SKIP (no valid email)';
      withMissingEmail++;
    } else if (entry.hasAuthUid) {
      entry.action = 'SKIP (already has authUid)';
      alreadyExists++;
    } else {
      entry.action = 'CREATE';
      wouldCreate++;
      withValidEmail++;
    }

    if (isAdmin) {
      adminMember = doc.id;
      adminEmail = email;
      adminUid = existingAuthUid || null;

      // Check if admins/{uid} doc already exists
      if (existingAuthUid) {
        const adminDoc = await db.collection('admins').doc(existingAuthUid).get();
        adminDocExists = adminDoc.exists;
      }
    }

    results.push(entry);
  }

  // --- DRY-RUN: report only ---
  if (isDryRun) {
    console.log('=== DRY RUN ===\n');
    console.log(`Total members:         ${totalMembers}`);
    console.log(`Valid email:           ${withValidEmail}`);
    console.log(`Missing/invalid email: ${withMissingEmail}`);
    console.log(`Would be created:      ${wouldCreate}`);
    console.log(`Already have authUid:  ${alreadyExists}`);
    console.log(`Member docs updated:   ${wouldCreate}`);
    console.log(`Admin member found:    ${adminMember ? 'YES' : 'NO'}`);
    console.log(`Admin email:           ${adminEmail || 'N/A'}`);
    console.log(`Admin UID:             ${adminUid || '(would be created)'}`);
    console.log(`admins/{uid} created:  ${adminDocExists ? 'ALREADY EXISTS' : adminUid ? 'WOULD UPDATE' : 'WOULD CREATE'}`);
    console.log('');

    if (withMissingEmail > 0) {
      console.log('--- Members with missing/invalid email (skipped) ---');
      for (const r of results) {
        if (!r.hasEmail) {
          console.log(`  ${r.docId}: ${r.name} <${r.email}> mobile:${r.mobile}`);
        }
      }
      console.log('');
    }

    console.log('--- Action plan ---');
    for (const r of results) {
      console.log(`  ${r.action.padEnd(30)} ${r.docId}: ${r.name} <${r.email}>`);
    }

    console.log('\nDry run complete. No changes made.');
    return;
  }

  // --- APPLY ---
  console.log('=== APPLY ===\n');
  let created = 0;
  let skipped = 0;
  let errors = 0;
  let adminCreatedUid = null;

  for (const r of results) {
    if (!r.hasEmail || r.hasAuthUid) {
      skipped++;
      continue;
    }

    const password = r.isAdmin ? ADMIN_PASSWORD : MEMBER_PASSWORD;

    try {
      const userRecord = await auth.createUser({
        email: r.email,
        password,
        displayName: r.name,
      });
      const uid = userRecord.uid;

      await r.docRef.update({ authUid: uid });
      console.log(` OK  [${r.docId}]: created ${uid} for ${r.email}`);

      // Create admins/{uid} for admin member
      if (r.isAdmin) {
        await db.collection('admins').doc(uid).set({
          role: 'admin',
          email: r.email,
          mobile: r.mobile,
          createdAt: FieldValue.serverTimestamp(),
        });
        adminCreatedUid = uid;
        console.log(` OK  admins/${uid}: admin document created`);
      }

      created++;
    } catch (err) {
      if (err.code === 'auth/email-already-exists') {
        try {
          const userRecord = await auth.getUserByEmail(r.email);
          const uid = userRecord.uid;
          await r.docRef.update({ authUid: uid });
          console.log(` DUP [${r.docId}]: linked existing ${uid} for ${r.email}`);

          // Still create admin doc if missing
          if (r.isAdmin) {
            const adminDocRef = db.collection('admins').doc(uid);
            const snap = await adminDocRef.get();
            if (!snap.exists) {
              await adminDocRef.set({
                role: 'admin',
                email: r.email,
                mobile: r.mobile,
                createdAt: FieldValue.serverTimestamp(),
              });
              console.log(` OK  admins/${uid}: admin document created (existing user)`);
            } else {
              console.log(` SKIP admins/${uid}: already exists`);
            }
            adminCreatedUid = uid;
          }

          created++;
        } catch (e2) {
          console.error(` ERR [${r.docId}]: failed to link existing user for ${r.email}: ${e2.message}`);
          errors++;
        }
      } else {
        console.error(` ERR [${r.docId}]: ${err.message} (${r.email})`);
        errors++;
      }
    }
  }

  // Summary
  console.log('\n=== Migration Summary ===');
  console.log(`  Users created/linked: ${created}`);
  console.log(`  Skipped (no email / already has authUid): ${skipped}`);
  console.log(`  Errors:               ${errors}`);
  console.log(`  Total docs:           ${totalMembers}`);
  if (adminCreatedUid) {
    console.log(`  Admin UID:            ${adminCreatedUid}`);
    console.log(`  Admin doc:            admins/${adminCreatedUid} created/verified`);
  }

  // Report skipped members with missing emails
  const noEmailResults = results.filter(r => !r.hasEmail);
  if (noEmailResults.length > 0) {
    console.log('\n--- Members skipped (no valid email) ---');
    for (const r of noEmailResults) {
      console.log(`  ${r.docId}: ${r.name} <${r.email}>`);
    }
  }

  process.exit(errors > 0 ? 1 : 0);
}

run();
