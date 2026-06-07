const { initializeApp, applicationDefault, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

const args = process.argv.slice(2);
const saArg = args.find(a => a.startsWith('--service-account='));
const saPath = saArg ? saArg.split('=')[1] : undefined;

if (saPath) {
  const serviceAccount = require(saPath);
  initializeApp({ credential: cert(serviceAccount) });
} else {
  initializeApp({ credential: applicationDefault() });
}

const auth = getAuth();
const db = getFirestore();

async function run() {
  const membersSnapshot = await db.collection('members').get();
  let updated = 0;
  let errors = 0;
  let adminUid = null;
  const ADMIN_MOBILE = '01853548853';

  for (const doc of membersSnapshot.docs) {
    const data = doc.data();
    const authUid = data.authUid || '';
    const email = (data.email || '').trim().toLowerCase();
    const mobile = (data.mobile || '').replace(/[^\d]/g, '');
    const isAdmin = mobile === ADMIN_MOBILE;

    if (!authUid || !email) continue;

    try {
      await auth.updateUser(authUid, { emailVerified: true });
      console.log(` OK  [${doc.id}]: ${email} -> emailVerified: true`);
      updated++;
      if (isAdmin) {
        adminUid = authUid;
        console.log(`      ^^ Admin user: ${email} (UID: ${authUid})`);
      }
    } catch (err) {
      console.error(` ERR [${doc.id}]: ${err.message} (${email})`);
      errors++;
    }
  }

  console.log('\n=== Results ===');
  console.log(`  Users marked emailVerified: ${updated}`);
  console.log(`  Errors:                    ${errors}`);
  if (adminUid) {
    console.log(`  Admin UID:                 ${adminUid}`);
    console.log(`  Admin emailVerified:       true`);
  }
  process.exit(errors > 0 ? 1 : 0);
}

run();
