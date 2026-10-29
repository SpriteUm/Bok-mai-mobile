// ทดสอบ firestore.rules กับ emulator ในเครื่อง (ไม่แตะโปรดักชัน)
// รัน: firebase emulators:exec --only firestore "node scripts/test_rules.js"
const P = 'bok-mai-db';
const BASE = `http://127.0.0.1:8080/v1/projects/${P}/databases/(default)/documents`;
const doc = (p) => `projects/${P}/databases/(default)/documents/${p}`;

const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const token = (uid) => {
  const now = Math.floor(Date.now() / 1000);
  return `${b64({ alg: 'none', typ: 'JWT' })}.${b64({
    sub: uid, user_id: uid, iss: `https://securetoken.google.com/${P}`, aud: P,
    iat: now, exp: now + 3600, auth_time: now, firebase: { sign_in_provider: 'password' },
  })}.`;
};

const v = (x) => {
  if (typeof x === 'string') return { stringValue: x };
  if (Number.isInteger(x)) return { integerValue: String(x) };
  if (Array.isArray(x)) return { arrayValue: { values: x.map(v) } };
  if (x && x.lat !== undefined) return { geoPointValue: { latitude: x.lat, longitude: x.lng } };
  if (x instanceof Date) return { timestampValue: x.toISOString() };
  return { mapValue: { fields: Object.fromEntries(Object.entries(x).map(([k, y]) => [k, v(y)])) } };
};
const fields = (o) => Object.fromEntries(Object.entries(o).map(([k, y]) => [k, v(y)]));

async function commit(auth, writes) {
  const r = await fetch(`${BASE}:commit`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${auth}` },
    body: JSON.stringify({ writes }),
  });
  return r.ok ? 'ALLOW' : `DENY (${r.status})`;
}
const set = (path, data) => ({ update: { name: doc(path), fields: fields(data) } });
const del = (path) => ({ delete: doc(path) });
const patch = (path, data, extraTs = []) => ({
  update: { name: doc(path), fields: fields(data) },
  updateMask: { fieldPaths: [...Object.keys(data), ...extraTs] },
  updateTransforms: extraTs.map((f) => ({ fieldPath: f, setToServerValue: 'REQUEST_TIME' })),
});
const createTs = (path, data, ts) => ({
  update: { name: doc(path), fields: fields(data) },
  currentDocument: { exists: false },
  updateTransforms: ts.map((f) => ({ fieldPath: f, setToServerValue: 'REQUEST_TIME' })),
});

const issue = (status, count, reporter = 'u1') => ({
  reporterId: reporter, categoryCode: 'road', title: 't', description: 'd', urgency: 'low',
  status, location: { lat: 13.7, lng: 100.7 }, geohash: 'w', addressText: 'a',
  reportCount: count, images: [], createdAt: new Date(), updatedAt: new Date(),
});
const feed = (status, count) => { const { reporterId, ...rest } = issue(status, count); return rest; };

let failed = 0;
function expect(name, got, want) {
  const ok = got.startsWith(want);
  if (!ok) failed++;
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}: ${got} (expected ${want})`);
}

(async () => {
  // seed (owner bypasses rules)
  await commit('owner', [
    set('categories/road', { name: 'road' }),
    set('admins/a1', { x: 1 }), set('admins/a2', { x: 1 }),
    set('users/a1', { displayName: 'สมชาย แอดมิน', email: 'a1@x.com' }),
    // resolved, no +1 (like the screenshot)
    set('issues/r1', issue('resolved', 1)), set('issues_feed/r1', feed('resolved', 1)),
    set('issues/r2', issue('resolved', 1)), set('issues_feed/r2', feed('resolved', 1)),
    // someone pressed +1 (only feed count increments)
    set('issues/f1', issue('pending', 1)), set('issues_feed/f1', feed('pending', 2)),
    // legacy report without feed copy
    set('issues/old', issue('pending', 1)),
    // editable
    set('issues/p1', issue('pending', 1)), set('issues_feed/p1', feed('pending', 1)),
    set('issues/r3', issue('resolved', 1)), set('issues_feed/r3', feed('resolved', 1)),
  ]);

  const u1 = token('u1'), u2 = token('u2'), a1 = token('a1'), a2 = token('a2');

  expect('owner deletes resolved report (issues + feed)', await commit(u1, [del('issues/r1'), del('issues_feed/r1')]), 'ALLOW');
  expect('other user deletes report', await commit(u2, [del('issues/r2'), del('issues_feed/r2')]), 'DENY');
  expect('owner deletes only issues, leaves feed', await commit(u1, [del('issues/r2')]), 'DENY');
  expect('owner deletes report with +1', await commit(u1, [del('issues/f1'), del('issues_feed/f1')]), 'DENY');
  expect('owner deletes legacy report w/o feed copy', await commit(u1, [del('issues/old')]), 'ALLOW');

  const edit = { title: 'แก้แล้ว', description: 'dd', categoryCode: 'road', urgency: 'high', addressText: 'b' };
  expect('owner edits pending report', await commit(u1, [patch('issues/p1', edit, ['updatedAt']), patch('issues_feed/p1', edit, ['updatedAt'])]), 'ALLOW');
  expect('owner edits resolved report', await commit(u1, [patch('issues/r3', edit, ['updatedAt']), patch('issues_feed/r3', edit, ['updatedAt'])]), 'DENY');
  expect('other user edits report', await commit(u2, [patch('issues/p1', edit, ['updatedAt']), patch('issues_feed/p1', edit, ['updatedAt'])]), 'DENY');

  const note = { actorId: 'a1', actorName: 'สมชาย แอดมิน', status: 'resolved', note: 'เรียบร้อย' };
  expect('admin sends signed feedback', await commit(a1, [createTs('issues/r3/updates/n1', note, ['createdAt'])]), 'ALLOW');
  expect('non-admin sends feedback on others report', await commit(u2, [createTs('issues/r3/updates/n2', { ...note, actorId: 'u2' }, ['createdAt'])]), 'DENY');
  expect('admin edits own note after resolved', await commit(a1, [patch('issues/r3/updates/n1', { note: 'แก้ข้อความ' }, ['editedAt'])]), 'ALLOW');
  expect('admin edits another admin note', await commit(a2, [patch('issues/r3/updates/n1', { note: 'x' }, ['editedAt'])]), 'DENY');
  expect('admin changes signed name', await commit(a1, [patch('issues/r3/updates/n1', { actorName: 'คนอื่น' }, ['editedAt'])]), 'DENY');
  expect('owner re-open writes update without actorName', await commit(u1, [createTs('issues/r3/updates/n3', { actorId: 'u1', status: 'in_progress', note: '' }, ['createdAt'])]), 'ALLOW');

  console.log(failed ? `\n${failed} FAILED` : '\nALL PASSED');
  process.exit(failed ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
