// ลงข้อมูลหมวดหมู่ใน seed/categories.json
// กับ emulator ตั้ง FIRESTORE_EMULATOR_HOST=localhost:8080 ก่อนรัน
const { initializeApp } = require('../functions/node_modules/firebase-admin/app');
const { getFirestore } = require('../functions/node_modules/firebase-admin/firestore');
const categories = require('../seed/categories.json');

initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'bok-mai-dev' });
const db = getFirestore();

(async () => {
  const batch = db.batch();
  for (const { code, nameTh } of categories) {
    batch.set(db.collection('categories').doc(code), { nameTh });
  }
  await batch.commit();
  console.log(`seeded ${categories.length} categories`);
})();
