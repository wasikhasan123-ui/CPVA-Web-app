/**
 * Migration script: Migrate legacy password members to Firebase Auth.
 *
 * Prerequisites:
 *   1. npm install firebase-admin
 *   2. Set GOOGLE_APPLICATION_CREDENTIALS or pass --service-account=path/to/key.json
 *   3. Ensure the service account has Firebase Authentication Admin + Firestore access
 *
 * Usage:
 *   node tool/migrate_to_firebase_auth.js [--service-account=path/to/key.json] [--project=project-id]
 *
 * What it does:
 *   - Reads all member documents from Firestore (members collection)
 *   - For each member that has a non-empty password and no authUid:
 *       - Creates a Firebase Auth user with email + password
 *       - Stores the authUid back in the member document
 *   - Skips members that already have an authUid
 *   - Skips members without a password (no legacy account)
 *   - Handles duplicate email errors gracefully (matches existing user)
 */

const { initializeApp, applicationDefault, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

const args = process.argv.slice(2);
const projectArg = args.find(a => a.startsWith('--project='));
const saArg = args.find(a => a.startsWith('--service-account='));
const projectId = projectArg ? projectArg.split('=')[1] : undefined;
const saPath = saArg ? saArg.split('=')[1] : undefined;

if (saPath) {
  const serviceAccount = require(saPath);
  initializeApp({ credential: cert(serviceAccount), projectId });
} else {
  initializeApp({ credential: applicationDefault(), projectId });
}

const auth = getAuth();
const db = getFirestore();

async function migrate() {
  const membersSnapshot = await db.collection('members').get();
  console.log(`Found ${membersSnapshot.size} member documents.`);

  let created = 0;
  let skipped = 0;
  let errors = 0;

  for (const doc of membersSnapshot.docs) {
    const data = doc.data();
    const email = (data.email || '').trim();
    const password = data.password || '';
    const existingAuthUid = data.authUid || '';

    if (!email) {
      console.log(`SKIP [${doc.id}]: no email`);
      skipped++;
      continue;
    }

    if (existingAuthUid) {
      console.log(`SKIP [${doc.id}]: already has authUid (${existingAuthUid})`);
      skipped++;
      continue;
    }

    if (!password) {
      console.log(`SKIP [${doc.id}]: no password (${email})`);
      skipped++;
      continue;
    }

    try {
      const userRecord = await auth.createUser({
        email,
        password,
        displayName: data.name || '',
        phoneNumber: data.mobile ? `+880${data.mobile.replace(/[^\d]/g, '').replace(/^0+/, '')}` : undefined,
      });
      await doc.ref.update({ authUid: userRecord.uid });
      console.log(` OK  [${doc.id}]: created ${userRecord.uid} for ${email}`);
      created++;
    } catch (err) {
      if (err.code === 'auth/email-already-exists') {
        try {
          const userRecord = await auth.getUserByEmail(email);
          await doc.ref.update({ authUid: userRecord.uid });
          console.log(`DUP  [${doc.id}]: linked existing ${userRecord.uid} for ${email}`);
          created++;
        } catch (e2) {
          console.error(`ERR  [${doc.id}]: failed to link existing user for ${email}: ${e2.message}`);
          errors++;
        }
      } else {
        console.error(`ERR  [${doc.id}]: ${err.message} (${email})`);
        errors++;
      }
    }
  }

  console.log('\n=== Migration Summary ===');
  console.log(`  Created/Linked: ${created}`);
  console.log(`  Skipped:        ${skipped}`);
  console.log(`  Errors:         ${errors}`);
  console.log(`  Total docs:     ${membersSnapshot.size}`);
  process.exit(errors > 0 ? 1 : 0);
}

migrate();
