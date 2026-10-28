import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

initializeApp();
setGlobalOptions({ region: 'asia-southeast1' });
const db = getFirestore();

const STATUSES = ['pending', 'in_progress', 'resolved'];

function requireAuth(uid: string | undefined): string {
  if (!uid) throw new HttpsError('unauthenticated', 'ต้องเข้าสู่ระบบ');
  return uid;
}

// ซิงก์ issues -> issues_feed (ตัด reporterId ออก)
export const onIssueWrite = onDocumentWritten('issues/{issueId}', async (event) => {
  const feedRef = db.collection('issues_feed').doc(event.params.issueId);
  const after = event.data?.after;
  if (!after?.exists) {
    await feedRef.delete();
    return;
  }
  const { reporterId: _reporterId, ...publicData } = after.data()!;
  await feedRef.set(publicData, { merge: true });
});

// กด +1 ติดตามปัญหา (ใช้ uid เป็น doc id กันกดซ้ำ)
export const followIssue = onCall(async (req) => {
  const uid = requireAuth(req.auth?.uid);
  const issueId = String(req.data?.issueId ?? '');
  if (!issueId) throw new HttpsError('invalid-argument', 'ต้องระบุ issueId');

  const issueRef = db.collection('issues').doc(issueId);
  const followerRef = db.collection('issues_feed').doc(issueId).collection('followers').doc(uid);

  await db.runTransaction(async (tx) => {
    const [issue, follower] = await Promise.all([tx.get(issueRef), tx.get(followerRef)]);
    if (!issue.exists) throw new HttpsError('not-found', 'ไม่พบปัญหา');
    if (follower.exists) throw new HttpsError('already-exists', 'ติดตามแล้ว');
    tx.set(followerRef, { createdAt: FieldValue.serverTimestamp() });
    tx.update(issueRef, {
      reportCount: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
});

// ผู้แจ้งกด Re-open: resolved -> in_progress
export const reopenIssue = onCall(async (req) => {
  const uid = requireAuth(req.auth?.uid);
  const issueId = String(req.data?.issueId ?? '');
  const images: { path: string }[] = req.data?.images ?? [];
  const note = String(req.data?.note ?? '');
  if (!issueId) throw new HttpsError('invalid-argument', 'ต้องระบุ issueId');

  const issueRef = db.collection('issues').doc(issueId);
  await db.runTransaction(async (tx) => {
    const issue = await tx.get(issueRef);
    if (!issue.exists) throw new HttpsError('not-found', 'ไม่พบปัญหา');
    const data = issue.data()!;
    if (data.reporterId !== uid) throw new HttpsError('permission-denied', 'ไม่ใช่เจ้าของเรื่อง');
    if (data.status !== 'resolved') throw new HttpsError('failed-precondition', 'ปัญหายังไม่ resolved');

    const patch: Record<string, unknown> = {
      status: 'in_progress',
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (images.length) {
      patch.images = FieldValue.arrayUnion(...images.map((i) => ({ path: i.path, kind: 'reopen' })));
    }
    tx.update(issueRef, patch);
    tx.set(issueRef.collection('updates').doc(), {
      actorId: uid,
      status: 'in_progress',
      note,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
});

// admin เปลี่ยนสถานะ + หมายเหตุ + รูปหลังแก้ไข
export const adminUpdateStatus = onCall(async (req) => {
  const uid = requireAuth(req.auth?.uid);
  if (req.auth?.token.admin !== true) throw new HttpsError('permission-denied', 'เฉพาะ admin');

  const issueId = String(req.data?.issueId ?? '');
  const status = String(req.data?.status ?? '');
  const note = String(req.data?.note ?? '');
  const images: { path: string }[] = req.data?.images ?? [];
  if (!issueId) throw new HttpsError('invalid-argument', 'ต้องระบุ issueId');
  if (!STATUSES.includes(status)) throw new HttpsError('invalid-argument', 'status ไม่ถูกต้อง');

  const issueRef = db.collection('issues').doc(issueId);
  const patch: Record<string, unknown> = { status, updatedAt: FieldValue.serverTimestamp() };
  if (images.length) {
    patch.images = FieldValue.arrayUnion(...images.map((i) => ({ path: i.path, kind: 'resolution' })));
  }
  const batch = db.batch();
  batch.update(issueRef, patch);
  batch.set(issueRef.collection('updates').doc(), {
    actorId: uid,
    status,
    note,
    createdAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();
});

// TODO: ฟังก์ชันที่ต้องใช้ Gemini (เก็บ GEMINI_API_KEY ด้วย `firebase functions:secrets:set GEMINI_API_KEY`)
//  - checkDuplicate: ค้น geohash รัศมี ~50 ม. + หมวดเดียวกัน + ยังไม่ resolved แล้วให้ Gemini เทียบรูป
//  - onFeedbackCreate: วิเคราะห์ sentiment -> เขียน sentiment/isUrgent กลับ + แจ้งเตือนเมื่อ urgent
//  - transcribeReport: รับไฟล์เสียง -> { title, description, urgency }
const notImplemented = () => {
  throw new HttpsError('unimplemented', 'not implemented');
};
export const checkDuplicate = onCall(notImplemented);
export const transcribeReport = onCall(notImplemented);
