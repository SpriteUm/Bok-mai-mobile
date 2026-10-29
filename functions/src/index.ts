import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { geminiConfig } from './config';

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
    if (issue.data()!.reporterId === uid) throw new HttpsError('failed-precondition', 'เจ้าของเรื่องนับเป็น 1 อยู่แล้ว');
    if (follower.exists) throw new HttpsError('already-exists', 'ติดตามแล้ว');
    tx.set(followerRef, { createdAt: FieldValue.serverTimestamp() });
    tx.update(issueRef, {
      reportCount: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
});

// ยกเลิก +1
export const unfollowIssue = onCall(async (req) => {
  const uid = requireAuth(req.auth?.uid);
  const issueId = String(req.data?.issueId ?? '');
  if (!issueId) throw new HttpsError('invalid-argument', 'ต้องระบุ issueId');

  const issueRef = db.collection('issues').doc(issueId);
  const followerRef = db.collection('issues_feed').doc(issueId).collection('followers').doc(uid);

  await db.runTransaction(async (tx) => {
    const [issue, follower] = await Promise.all([tx.get(issueRef), tx.get(followerRef)]);
    if (!issue.exists) throw new HttpsError('not-found', 'ไม่พบปัญหา');
    if (!follower.exists) throw new HttpsError('failed-precondition', 'ยังไม่ได้ติดตาม');
    tx.delete(followerRef);
    tx.update(issueRef, {
      reportCount: Math.max((issue.data()!.reportCount ?? 1) - 1, 1),
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

// Voice-to-Report: ให้ Gemini ร่างแบบฟอร์มจากข้อความที่ผู้ใช้พูด (ผู้ใช้ตรวจแก้ได้ก่อนส่ง)
const REPORT_CATEGORIES = ['electric', 'water', 'road', 'waste', 'drainage', 'other'];
const REPORT_URGENCIES = ['low', 'medium', 'high'];

export const draftReport = onCall(async (req) => {
  requireAuth(req.auth?.uid);
  const transcript = String(req.data?.transcript ?? '').trim().slice(0, 2000);
  if (!transcript) throw new HttpsError('invalid-argument', 'ต้องระบุข้อความ');

  const { apiKey, model } = geminiConfig();
  const prompt =
    'คุณคือผู้ช่วยร่างแบบฟอร์มแจ้งปัญหาสาธารณะของเมืองในประเทศไทย ' +
    'จากคำพูดของผู้ใช้ต่อไปนี้ ให้ร่างแบบฟอร์มเป็นภาษาไทย ' +
    'title คือหัวข้อสั้นไม่เกิน 60 ตัวอักษร, ' +
    'description คือรายละเอียดที่เรียบเรียงใหม่ให้อ่านง่าย โดยไม่เพิ่มข้อเท็จจริงที่ผู้ใช้ไม่ได้พูด, ' +
    `category เลือกจาก ${REPORT_CATEGORIES.join('|')} ` +
    '(electric=ไฟฟ้า, water=ประปา/น้ำท่วม, road=ถนน/ทางเท้า, waste=ขยะ, drainage=ท่อระบายน้ำ, other=อื่นๆ), ' +
    'urgency เลือก high เมื่อมีอันตรายต่อชีวิตหรือกระทบการสัญจรรุนแรง, low เมื่อไม่กระทบใคร, นอกนั้น medium\n\n' +
    `คำพูดผู้ใช้: """${transcript}"""`;

  const res = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        responseMimeType: 'application/json',
        responseSchema: {
          type: 'OBJECT',
          properties: {
            title: { type: 'STRING' },
            description: { type: 'STRING' },
            category: { type: 'STRING', enum: REPORT_CATEGORIES },
            urgency: { type: 'STRING', enum: REPORT_URGENCIES },
          },
          required: ['title', 'description', 'category', 'urgency'],
        },
      },
    }),
  });
  if (!res.ok) throw new HttpsError('internal', `Gemini ตอบกลับผิดพลาด (${res.status})`);

  const body = (await res.json()) as { candidates?: { content?: { parts?: { text?: string }[] } }[] };
  const text = body.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) throw new HttpsError('internal', 'Gemini ไม่ส่งผลลัพธ์กลับมา');

  const out = JSON.parse(text) as Record<string, unknown>;
  return {
    title: String(out.title ?? '').slice(0, 80),
    description: String(out.description ?? transcript),
    category: REPORT_CATEGORIES.includes(String(out.category)) ? out.category : 'other',
    urgency: REPORT_URGENCIES.includes(String(out.urgency)) ? out.urgency : 'medium',
  };
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
