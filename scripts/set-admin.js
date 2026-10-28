// ใช้: node scripts/set-admin.js admin@example.com
// กับ emulator ตั้ง FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 ก่อนรัน
const { initializeApp } = require('../functions/node_modules/firebase-admin/app');
const { getAuth } = require('../functions/node_modules/firebase-admin/auth');

const email = process.argv[2];
if (!email) {
  console.error('usage: node scripts/set-admin.js <email>');
  process.exit(1);
}

initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'bok-mai-dev' });

(async () => {
  const auth = getAuth();
  const user = await auth.getUserByEmail(email);
  await auth.setCustomUserClaims(user.uid, { admin: true });
  console.log(`${email} (${user.uid}) is now admin - ต้องออกจากระบบแล้วเข้าใหม่`);
})();
