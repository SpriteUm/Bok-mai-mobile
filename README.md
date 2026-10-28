# Bok Mai (บอกไหม) – แอปแจ้งปัญหาสาธารณะ

แอปมือถือสำหรับให้ประชาชนแจ้งปัญหาสาธารณะ (ไฟฟ้า, น้ำประปา, ถนน, ขยะ ฯลฯ) พร้อมรูปภาพและพิกัด GPS
ให้เจ้าหน้าที่จัดการสถานะงาน และให้ผู้แจ้งติดตามความคืบหน้าแบบเรียลไทม์ โดยมี AI (Gemini) ช่วยกรอกฟอร์ม ตรวจแจ้งซ้ำ และวิเคราะห์ความพึงพอใจ

> เอกสารนี้เขียนให้ทั้งคนและ AI Agent อ่านเพื่อเริ่มสร้างโปรเจกต์ได้ทันที
> ส่วนที่ระบุ `[TODO]` = ยังไม่ได้ทำ / ต้องตัดสินใจเพิ่ม

---

## 1. Tech Stack

| ส่วน | เทคโนโลยี |
|---|---|
| Mobile App | **Flutter** (Dart) – โค้ดเดียวรองรับ Android / iOS |
| Local DB (Offline-first & Cache) | **Firestore offline persistence** (มีในตัว ไม่ต้องเพิ่มไลบรารี) — Drift ใช้เฉพาะถ้าต้องการคิวออฟไลน์ที่ซับซ้อนกว่านี้ (ดูข้อ 10) |
| AI Engine | Google **Gemini API** |
| Backend / Database | **Firebase – Cloud Firestore** (NoSQL) |
| Authentication | **Firebase Authentication** |
| File Storage | **Cloud Storage for Firebase** |
| Realtime | Firestore real-time listeners (`snapshots()`) |
| Server-side Logic | **Cloud Functions for Firebase** (Node.js / TypeScript) |
| Push Notification | **Firebase Cloud Messaging (FCM)** |
| Dev / Local | **Firebase Emulator Suite** (จำลอง Auth, Firestore, Storage, Functions ในเครื่อง) |

---

## 2. ผู้ใช้งานและสิทธิ์ (Roles)

| Role | สิทธิ์ |
|---|---|
| `user` (ประชาชน) | แจ้งปัญหา, ดู Feed สาธารณะ, ดูแผนที่, ดูประวัติและติดตามสถานะของตัวเอง, ให้คะแนน, ขอเปิดเรื่องซ้ำ, กด +1 |
| `admin` (เจ้าหน้าที่) | ดูปัญหาทั้งหมด, ค้นหา/กรอง, ดูแผนที่รวม, เปลี่ยนสถานะ, บันทึกหมายเหตุ, แนบรูปหลังแก้ไข, ดูผล Sentiment |

- การบังคับสิทธิ์ทำที่ฝั่งเซิร์ฟเวอร์ด้วย **Firebase Security Rules** (Firestore + Storage) ไม่ใช่แค่ซ่อนปุ่มใน UI
- Role `admin` เก็บเป็น **Custom Claim** (`admin: true`) บน Firebase Auth token ซึ่งตั้งได้ผ่าน Admin SDK เท่านั้น ผู้ใช้แก้เองจากแอปไม่ได้

---

## 3. ภาพรวม User Flow

```
User → เปิดแอป → Homepage ── Home Feed (สไตล์ Facebook)
                     │
                 Action Button
        ┌────────────┼─────────────┬──────────────┐
        ▼            ▼             ▼              ▼
   1. แผนที่      2. ฟอร์ม      3. ประเมิน     4. ประวัติ
   รวมจุดเกิดเหตุ  แจ้งปัญหา AI   และข้อเสนอแนะ  และติดตามสถานะ
```

---

## 4. หน้าจอและฟีเจอร์

### 4.0 Home Feed (สไตล์ Facebook)
ฟีดแสดงปัญหาที่ทุกคนแจ้ง **ไม่มีปุ่ม Like / Comment และไม่แสดงชื่อผู้แจ้ง** (เพื่อความเป็นส่วนตัว)

แต่ละการ์ดแสดง:
- รูปภาพปัญหา
- หัวข้อ / รายละเอียด
- สถานะปัญหา (รอดำเนินการ / กำลังดำเนินการ / แก้ไขแล้ว)
- ตำแหน่งที่เกิดเหตุ (ที่อยู่ย่อ + มินิแมป)
- จำนวนผู้แจ้ง (นับจาก +1)

เมื่อกดเข้าการ์ด: ดูรายละเอียดเต็ม, ดูรูปทั้งหมด, ดูตำแหน่งบนแผนที่, ดูสถานะ, ดูจำนวนผู้แจ้ง

### 4.1 แผนที่รวมจุดเกิดเหตุ (Interactive Map View)
- แสดงหมุดปัญหารอบตัวตามพิกัด GPS ปัจจุบันของผู้ใช้ (ค้นหาด้วย geohash — ดูข้อ 6)
- กรองหมุดตามหมวดหมู่ (ไฟฟ้า, ถนน ฯลฯ) และสถานะ (รอดำเนินการ, แก้ไขแล้ว)
- แตะหมุดเพื่อดูป็อปอัปสรุป: รูป, สถานะ, ชื่อปัญหา
- ฝั่ง Admin: เห็นหมุดทุกจุดในพื้นที่เพื่อวางแผนลงพื้นที่เป็นโซน

### 4.2 ฟอร์มแจ้งปัญหาอัจฉริยะ (Smart Report Form)
1. **แนบรูปภาพ** – ถ่ายสดหรือเลือกจากคลังภาพ ระบบ **เบลอใบหน้าและป้ายทะเบียนอัตโนมัติ** ก่อนอัปโหลด (PDPA)
2. **Voice-to-Report** – กดอัดเสียงพูดรายละเอียด → AI แปลงเป็นข้อความ และสร้าง "หัวข้อ" + "รายละเอียด" ลงฟอร์ม
3. **ระบุพิกัด** – ดึง GPS อัตโนมัติ หรือเปิดแผนที่ลากหมุดปรับตำแหน่ง
4. **ตรวจจับแจ้งซ้ำ (AI Duplicate Check)** – เทียบพิกัด + รูปกับปัญหาเดิม ถ้าซ้ำ ปุ่ม "ส่ง" จะเปลี่ยนเป็น **"+1 ติดตามปัญหา"**
5. เลือกหมวดหมู่ (ไฟฟ้า, น้ำประปา, ถนน, ขยะ, อื่นๆ) และระดับความเร่งด่วน

### 4.3 ประวัติและการติดตามสถานะ (History & Status Tracking)
- รายการปัญหา (Tickets) ทั้งหมดที่ผู้ใช้เคยแจ้ง
- แท็บกรองสถานะ: `[รอดำเนินการ]` `[กำลังดำเนินการ]` `[แก้ไขแล้ว]` อัปเดตเรียลไทม์
- **Timeline** ความคืบหน้า: เจ้าหน้าที่รับเรื่อง → ส่งทีมช่าง → แก้ไขเสร็จ
- ดูผลงานหลังแก้ไข: รูปหลักฐาน + หมายเหตุจากเจ้าหน้าที่

### 4.4 ประเมินและรับข้อเสนอแนะ (Feedback System)
- ให้คะแนน 1–5 ดาว + เลือกแท็กสำเร็จรูป หรือพิมพ์เพิ่ม
- **Re-open Issue** – กดแจ้งว่ายังไม่ได้รับการแก้ไขจริง ส่งเรื่องกลับเป็น "กำลังดำเนินการ" พร้อมแนบภาพใหม่
- **AI Sentiment Analysis** – Gemini วิเคราะห์ความรู้สึกจากข้อความ แจ้งเตือนผู้บริหารเมื่อเป็นเคสเร่งด่วน

### 4.5 ฝั่งผู้ดูแลระบบ (Admin)
- **Dashboard** – รายการปัญหาทั้งหมด ค้นหา / กรองตามหมวดหมู่, ความเร่งด่วน, สถานะ, ช่วงเวลา
- **Map Dashboard** – หมุดทุกปัญหาบนแผนที่
- **จัดการงาน** – เปลี่ยนสถานะ, บันทึกหมายเหตุ, แนบรูปหลังแก้ไข (ผู้แจ้งเห็นแบบเรียลไทม์)

---

## 5. สถานะของ Ticket (State Machine)

```
pending ──► in_progress ──► resolved
   ▲              ▲             │
   │              └── reopened ◄┘   (ผู้ใช้กด Re-open)
```

| status | ความหมาย |
|---|---|
| `pending` | รอดำเนินการ |
| `in_progress` | กำลังดำเนินการ (รวมกรณีถูก reopen) |
| `resolved` | แก้ไขแล้ว |

---

## 6. Data Model (ร่างเริ่มต้นสำหรับ Cloud Firestore)

> **Source of truth คือไฟล์ [`firestore.rules`](firestore.rules), [`storage.rules`](storage.rules), [`firestore.indexes.json`](firestore.indexes.json) และโค้ดใน [`functions/`](functions/)** — โครงสร้างด้านล่างเป็นภาพรวมเพื่ออ่านเท่านั้น
> Firestore เป็น NoSQL: ไม่มี JOIN / View / RLS / PostGIS จึงใช้ **2 คอลเลกชันคู่ (`issues` + `issues_feed`)**, **geohash** แทน PostGIS และ **callable Cloud Functions** แทน RPC

### คอลเลกชัน

```
users/{uid}
  displayName: string
  createdAt: timestamp
  (role ไม่เก็บที่นี่ → ใช้ Custom Claim `admin` บน Auth token)

categories/{code}                 // electric, water, road, waste, other
  nameTh: string

issues/{issueId}                  // ข้อมูลเต็ม (มี reporterId) — เจ้าของ + admin อ่านได้เท่านั้น
  reporterId: string
  categoryCode: string
  title: string
  description: string
  urgency: 'low' | 'medium' | 'high'            // default 'medium'
  status: 'pending' | 'in_progress' | 'resolved' // default 'pending'
  location: GeoPoint
  geohash: string                                // สำหรับค้นหาแบบรัศมี
  addressText: string
  reportCount: number                            // จำนวนผู้แจ้ง (รวม +1) default 1
  images: [{ path: string, kind: 'report' | 'resolution' | 'reopen' }]
  createdAt, updatedAt: timestamp

issues/{issueId}/updates/{updateId}   // Timeline / Log การเปลี่ยนสถานะ
  actorId: string
  status: string
  note: string
  createdAt: timestamp

issues_feed/{issueId}             // สำเนาสำหรับ Feed/Map — **ไม่มี reporterId** (Cloud Function ซิงก์ให้)
  categoryCode, title, description, urgency, status,
  location, geohash, addressText, reportCount, images,
  createdAt, updatedAt

issues_feed/{issueId}/followers/{uid}   // ผู้ที่กด +1 (ใช้ uid เป็น doc id เพื่อกันกดซ้ำ)
  createdAt: timestamp

feedback/{feedbackId}
  issueId: string
  userId: string
  rating: number (1–5)
  tags: string[]
  comment: string
  sentiment: 'positive' | 'neutral' | 'negative'   // เติมโดย Cloud Function
  isUrgent: boolean                                // เติมโดย Cloud Function
  createdAt: timestamp
```

### Cloud Functions (แทน RPC / Edge Functions)

| ฟังก์ชัน | ชนิด | หน้าที่ |
|---|---|---|
| `onIssueWrite` | Firestore trigger | ซิงก์ `issues` → `issues_feed` (ตัด `reporterId` ออก) |
| `checkDuplicate` | callable | ค้นปัญหารัศมี ~50 ม. ด้วย geohash แล้วส่งรูปคู่ใกล้เคียงให้ Gemini เทียบ |
| `followIssue` | callable | กด +1 (transaction: เช็คซ้ำ + เพิ่ม `reportCount`) |
| `reopenIssue` | callable | เปลี่ยน `resolved` → `in_progress` + แนบรูป + เขียน timeline |
| `adminUpdateStatus` | callable (admin เท่านั้น) | เปลี่ยนสถานะ + หมายเหตุ + รูปหลังแก้ไข + เขียน timeline |
| `onFeedbackCreate` | Firestore trigger | เรียก Gemini วิเคราะห์ sentiment → เขียนผลกลับ + แจ้งเตือนผู้บริหารเมื่อ urgent |
| `transcribeReport` | callable | Voice-to-Report ผ่าน Gemini |

**ค้นหาปัญหารอบตัว (แทน `nearby_issues`)**: เก็บ `geohash` ไว้ในเอกสาร แล้วใช้ไลบรารี geohash (`geoflutterfire_plus` ฝั่ง Flutter / `geofire-common` ฝั่ง Functions) สร้างช่วงค้นหา `orderBy('geohash').startAt().endAt()` แล้วกรองระยะจริงอีกรอบฝั่งโค้ด เพราะช่วง geohash จะได้เอกสารเกินวงกลมเล็กน้อย

**Composite index**: query ที่กรองหลายเงื่อนไข (เช่น `status` + `categoryCode` + `createdAt`) ต้องประกาศใน `firestore.indexes.json`

### Security Rules (แนวทาง)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() { return request.auth != null; }
    function isAdmin()  { return signedIn() && request.auth.token.admin == true; }
    function isOwner(uid) { return signedIn() && request.auth.uid == uid; }

    match /users/{uid} {
      allow read: if isOwner(uid) || isAdmin();
      allow create: if isOwner(uid);
      allow update: if isOwner(uid)
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['displayName']);
    }

    match /categories/{id} {
      allow read: if signedIn();
      allow write: if false;
    }

    match /issues/{issueId} {
      allow read: if isOwner(resource.data.reporterId) || isAdmin();
      allow create: if signedIn()
        && request.resource.data.reporterId == request.auth.uid
        && request.resource.data.status == 'pending'
        && request.resource.data.reportCount == 1;
      allow update, delete: if false;      // แก้ผ่าน callable Functions เท่านั้น

      match /updates/{updateId} {
        allow read: if isAdmin() || isOwner(
          get(/databases/$(database)/documents/issues/$(issueId)).data.reporterId);
        allow write: if false;
      }
    }

    match /issues_feed/{issueId} {
      allow read: if signedIn();
      allow write: if false;               // Cloud Function (Admin SDK) เขียนเท่านั้น
      match /followers/{uid} {
        allow read: if isOwner(uid);
        allow write: if false;
      }
    }

    match /feedback/{id} {
      allow read: if isAdmin() || (signedIn() && resource.data.userId == request.auth.uid);
      allow create: if signedIn()
        && request.resource.data.userId == request.auth.uid
        && request.resource.data.rating is int
        && request.resource.data.rating >= 1 && request.resource.data.rating <= 5
        && !('sentiment' in request.resource.data)
        && !('isUrgent' in request.resource.data);
      allow update, delete: if false;
    }
  }
}
```

> Cloud Functions ใช้ Admin SDK ซึ่งข้าม Security Rules ได้ จึงเขียนคอลเลกชันที่ client เขียนไม่ได้ (`issues_feed`, `updates`, `followers`) ได้ตามปกติ

### Storage Rules (แนวทาง)

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // รูปแจ้งปัญหา / รูป reopen — ผู้ใช้อัปโหลดเข้าโฟลเดอร์ตัวเองเท่านั้น
    match /reports/{uid}/{file} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid
        && request.resource.size < 10 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }
    match /reopens/{uid}/{file} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid
        && request.resource.size < 10 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }
    // รูปหลังแก้ไข — admin เท่านั้น
    match /resolutions/{issueId}/{file} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.admin == true
        && request.resource.size < 10 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }
  }
}
```

---

## 7. สถาปัตยกรรมแนะนำ

```
Flutter App ──► Firebase (Auth / Firestore / Cloud Storage / FCM)
     │                      │
     │                      └─► Cloud Functions ──► Gemini API
     └─► Firestore offline cache (คิวเขียนออฟไลน์ในตัว) ◄── sync อัตโนมัติเมื่อมีเน็ต
```

- **Offline-first**: Firestore เปิด offline persistence เป็นค่าเริ่มต้นบนมือถือ การ `add()` ตอนออฟไลน์จะเข้าคิวและ sync เอง (ข้อจำกัด: callable Functions เช่น `followIssue` ใช้ตอนออฟไลน์ไม่ได้)
- **Realtime**: `snapshots()` บน `issues` / `issues/{id}/updates` เพื่ออัปเดตสถานะบนหน้าจอผู้ใช้ทันที
- **AI**: เรียก Gemini ผ่าน Cloud Functions ไม่เรียกตรงจากแอป (ดูข้อ 10)

### โครงสร้าง Repository

```
Bok-mai-mobile/
├── lib/                    # Flutter app (ดูด้านล่าง)
├── functions/              # Cloud Functions (TypeScript) — เรียก Gemini, ซิงก์ feed, callable [TODO]
├── firebase.json           # ตั้งค่า emulators / deploy
├── .firebaserc             # project alias
├── firestore.rules         # Security Rules ของ Firestore
├── firestore.indexes.json  # Composite indexes
├── storage.rules           # Security Rules ของ Storage
├── seed/
│   └── categories.json     # ข้อมูลเริ่มต้น (หมวดหมู่)
├── scripts/
│   ├── seed.js             # ลงข้อมูลหมวดหมู่ (Admin SDK)
│   └── set-admin.js        # ตั้ง Custom Claim admin ให้อีเมลที่ระบุ
└── .env.example
```

### โครงสร้างโฟลเดอร์ Flutter (feature-first)

```
lib/
├── main.dart
├── firebase_options.dart   # สร้างโดย `flutterfire configure`
├── core/            # theme, router, constants, utils, firebase init
├── data/            # repositories, models
└── features/
    ├── auth/
    ├── feed/
    ├── map/
    ├── report/      # smart form, voice, image blur, duplicate check
    ├── history/     # tickets + timeline
    ├── feedback/
    └── admin/       # dashboard, map dashboard, manage issue
```

---

## 8. การติดตั้งและรันโปรเจกต์ (พร้อม Firebase Emulator)

แอปมือถือ Flutter รันบนอีมูเลเตอร์/เครื่องจริง ส่วน backend ตอนพัฒนารันด้วย **Firebase Emulator Suite** (Auth, Firestore, Storage, Functions) ในเครื่อง ไม่ต้องแตะข้อมูลจริงและไม่เสียเงิน ไม่ต้องใช้ Docker

### สิ่งที่ต้องมี
- [Flutter SDK](https://docs.flutter.dev/get-started/install), `git`
- [Node.js](https://nodejs.org/) (LTS) — ใช้กับ Firebase CLI และ Cloud Functions
- Firebase CLI: `npm i -g firebase-tools`
- Java (JDK) — Firestore Emulator ต้องใช้ ดูเวอร์ชันที่ต้องการจากข้อความของ `firebase-tools`
- บัญชี Google + โปรเจกต์ใน [Firebase Console](https://console.firebase.google.com/)
- **แผน Blaze (pay-as-you-go)** — จำเป็นสำหรับ Cloud Functions และ Cloud Storage (มี free tier ให้ใช้ก่อน) การรันบน Emulator ไม่คิดเงิน

### ขั้นตอน

```bash
git clone https://github.com/SpriteUm/Bok-mai-mobile.git
cd Bok-mai-mobile

firebase login
firebase use --add                 # เลือกโปรเจกต์ Firebase ของคุณ

# ผูกแอป Flutter กับโปรเจกต์ (สร้าง lib/firebase_options.dart)
dart pub global activate flutterfire_cli
flutterfire configure

# ติดตั้ง dependency ของ Functions
cd functions && npm install && cd ..

# เริ่ม emulators
firebase emulators:start
```

จากนั้นรันแอป (อีกเทอร์มินัล):

```bash
flutter pub get
flutter run
```

ใน `main.dart` ให้ต่อแอปเข้า emulator เฉพาะโหมด debug:

```dart
if (kDebugMode) {
  const host = '10.0.2.2'; // Android Emulator (iOS Simulator/Web/Desktop ใช้ 'localhost')
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  FirebaseFunctions.instanceFor(region: 'asia-southeast1').useFunctionsEmulator(host, 5001);
}
```

| คำสั่ง | ทำอะไร |
|---|---|
| `firebase emulators:start` | เริ่ม Auth / Firestore / Storage / Functions emulators |
| `firebase emulators:start --import=./emulator-data --export-on-exit` | เก็บ/โหลดข้อมูลทดสอบข้ามรอบ |
| `node scripts/seed.js` | ลงข้อมูลหมวดหมู่ (`seed/categories.json`) |
| `firebase deploy --only firestore:rules,firestore:indexes,storage` | ขึ้น rules และ index ไปโปรเจกต์จริง |
| `firebase deploy --only functions` | ขึ้น Cloud Functions |

เปิด Emulator UI ที่ <http://localhost:4000> เพื่อดูข้อมูลและผู้ใช้ทั้งหมด

**พอร์ตเริ่มต้นของ emulators และอุปกรณ์**

| บริการ | พอร์ต |
|---|---|
| Emulator UI | 4000 |
| Auth | 9099 |
| Firestore | 8080 |
| Storage | 9199 |
| Functions | 5001 |

| อุปกรณ์ | Host |
|---|---|
| iOS Simulator / Flutter Web / Desktop | `localhost` |
| Android Emulator | `10.0.2.2` |
| มือถือจริง (Wi-Fi เดียวกับคอมพิวเตอร์) | `<IP เครื่องคุณ>` — ตั้ง `"host": "0.0.0.0"` ของแต่ละ emulator ใน `firebase.json` และอนุญาตพอร์ตใน firewall |

> Android 9+ บล็อก HTTP แบบไม่เข้ารหัสโดยปริยาย ตอนพัฒนาให้เพิ่ม `android:usesCleartextTraffic="true"` ใน `AndroidManifest.xml` (เฉพาะ debug) ส่วน iOS ต้องตั้ง App Transport Security exception

### ตั้งให้ใครเป็น Admin
ผู้ใช้ทุกคนที่สมัครจะเป็น `user` เสมอ ให้ promote ด้วย Custom Claim ผ่านสคริปต์ที่ใช้ Admin SDK:

```bash
# ตัวอย่าง: รันกับ emulator (ตั้ง env ให้ Admin SDK ชี้ไป Auth Emulator)
FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 node scripts/set-admin.js admin@example.com
```

เนื้อหา `scripts/set-admin.js` โดยสรุป: หา user จากอีเมล (`getAuth().getUserByEmail`) แล้วเรียก `getAuth().setCustomUserClaims(uid, { admin: true })` — ผู้ใช้ต้อง **ออกจากระบบแล้วเข้าใหม่** (หรือ `getIdToken(true)`) เพื่อให้ token ได้ claim ใหม่
กับโปรเจกต์จริงให้ใช้ service account key เก็บไว้นอก repo เท่านั้น

### Environment variables

`.env.example`
```
# ค่า Firebase config (apiKey ฯลฯ) ไม่ใช่ความลับ — อยู่ใน firebase_options.dart ที่สร้างจาก flutterfire configure
# ห้ามใส่ GEMINI_API_KEY ในแอป → เก็บเป็น Secret ของ Cloud Functions
```

เพิ่มใน `.gitignore`:
```
.env
serviceAccountKey*.json
.firebase/
functions/.secret.local
functions/node_modules/
emulator-data/
```

### Gemini (AI) ตอนรันบน Firebase
ฟังก์ชัน AI อยู่ใน `functions/` เก็บคีย์ Gemini เป็น Secret ฝั่งเซิร์ฟเวอร์เท่านั้น:

```bash
firebase functions:secrets:set GEMINI_API_KEY
```

ตอนรันบน Emulator ให้ใส่คีย์ในไฟล์ `functions/.secret.local` (อยู่ใน `.gitignore`) แล้วประกาศ secret นั้นในฟังก์ชันที่ใช้ [TODO: เพิ่ม Cloud Function ตัวอย่าง]
ทางเลือก: **Firebase AI Logic** (เรียก Gemini จากแอปผ่าน Firebase โดยไม่ต้องมีคีย์ในแอป ใช้ร่วมกับ App Check) — เหมาะกับงานง่าย ๆ แต่ logic ที่ต้องคุมฝั่งเซิร์ฟเวอร์ (duplicate check, sentiment) ยังควรอยู่ใน Cloud Functions

### Troubleshooting
| อาการ | วิธีแก้ |
|---|---|
| พอร์ต 8080 (หรือพอร์ตอื่น) ถูกใช้อยู่ | แก้พอร์ตของ emulator นั้นใน `firebase.json` แล้วแก้ `useFirestoreEmulator(...)` ในแอปให้ตรงกัน |
| แอปต่อ emulator ไม่ได้บน Android | เช็คว่าใช้ `10.0.2.2` (emulator) หรือ IP เครื่องจริง และเปิด cleartext ตอน dev |
| Firestore Emulator ไม่เริ่ม | ตรวจว่าติดตั้ง Java แล้ว (`java -version`) และเวอร์ชันตรงกับที่ `firebase-tools` ต้องการ |
| `permission-denied` ตอนอ่าน/เขียน | ดูแท็บ Requests ใน Emulator UI เพื่อดูว่า rule ข้อไหนปฏิเสธ และเช็คว่าล็อกอินแล้ว |
| เป็น admin แล้วแต่ยังโดนปฏิเสธ | ผู้ใช้ต้องออกจากระบบแล้วเข้าใหม่ (หรือรีเฟรช token) หลังตั้ง Custom Claim |
| Query ฟ้อง `The query requires an index` | กดลิงก์ในข้อความ error เพื่อสร้าง index หรือเพิ่มใน `firestore.indexes.json` |
| Login ด้วย Google ไม่ผ่าน | เปิด Google provider ที่ Console → Authentication → Sign-in method และเพิ่ม SHA-1/SHA-256 ของแอป Android ในตั้งค่าโปรเจกต์ แล้วดาวน์โหลด `google-services.json` ใหม่ (ฝั่ง iOS ตั้ง URL scheme ตามที่ `flutterfire` แนะนำ) |
| ต้องการเริ่มข้อมูลทดสอบใหม่ | ลบโฟลเดอร์ `emulator-data/` แล้วเริ่ม emulators ใหม่ |

> ⚠️ ก่อนขึ้น production ต้องตรวจ Security Rules ทุกไฟล์ (ห้ามปล่อย `allow read, write: if true` เด็ดขาด), เปิด **App Check**, ตั้งงบประมาณ/แจ้งเตือนค่าใช้จ่าย (Budget alerts) บนแผน Blaze, ตั้ง SMTP/เทมเพลตอีเมลของ Auth ให้เรียบร้อย และเปิดการสำรองข้อมูล Firestore (scheduled backups / export)

สิทธิ์ที่ต้องขอในแอป: Camera, Photos, Location (When In Use), Microphone, Notifications

---

## 9. Roadmap (ลำดับการพัฒนาที่แนะนำ)

- [ ] **Phase 1 – Foundation**: ตั้งโปรเจกต์ Flutter + Firebase (`flutterfire configure`), Firebase Auth, Custom Claim admin, Firestore + Security Rules
- [ ] **Phase 2 – Core MVP**: ฟอร์มแจ้งปัญหา (รูป + GPS), Home Feed (`issues_feed`), History + Realtime status
- [ ] **Phase 3 – Map & Admin**: Map View + filter (geohash), Admin Dashboard, `adminUpdateStatus` + รูปหลังแก้ไข
- [ ] **Phase 4 – AI**: Voice-to-Report, Duplicate Check, เบลอหน้า/ป้ายทะเบียน
- [ ] **Phase 5 – Feedback**: ให้คะแนน, Re-open, Sentiment Analysis + แจ้งเตือนผู้บริหาร
- [ ] **Phase 6 – Polish**: ทดสอบ offline sync, FCM Push Notification, App Check, ทดสอบ, ขึ้น Store

---

## 10. ข้อเสนอแนะทางเทคนิค (Design Notes)

1. **อย่าเก็บ Gemini API Key ในแอป** – ไฟล์ที่ bundle ไปกับแอปถูกแกะได้ ให้เรียก Gemini ผ่าน Cloud Functions แล้วเก็บคีย์เป็น Secret (`firebase functions:secrets:set`) ฝั่งเซิร์ฟเวอร์
2. **เบลอใบหน้า/ป้ายทะเบียนทำบนเครื่อง** – Gemini วิเคราะห์ภาพได้แต่ไม่ได้ "แก้ไขภาพ" ใช้ Google ML Kit (Face Detection + Text Recognition สำหรับป้ายทะเบียน) แล้วเบลอด้วย Dart ก่อนอัปโหลด ข้อมูลส่วนบุคคลจะไม่ออกจากเครื่อง
3. **Duplicate Check ให้กรองด้วยพิกัดก่อน** – ใช้ geohash query หาปัญหาในรัศมี ~50 ม. หมวดเดียวกันที่ยังไม่ `resolved` แล้วกรองระยะจริงด้วยสูตร Haversine ก่อน จากนั้นค่อยส่งรูปคู่ที่ใกล้เคียงให้ Gemini เทียบ ประหยัดค่า API และแม่นยำกว่า
4. **Voice-to-Report** – ใช้ Gemini รับไฟล์เสียงโดยตรง (ถอดเสียง + สรุปหัวข้อใน call เดียว) หรือใช้ `speech_to_text` บนเครื่องแล้วให้ Gemini สรุป
5. **Local DB** – Firestore มี offline persistence ในตัว (cache + คิวเขียน) โดยทั่วไปไม่ต้องใช้ Drift/Isar/Hive เพิ่ม ใช้ Drift เฉพาะเมื่อต้องการ logic sync เฉพาะทางที่ Firestore ทำไม่ได้
6. **State management** – แนะนำ **Riverpod** + `go_router` (ห่อ Firestore streams เป็น `StreamProvider`)
7. **แผนที่** – `flutter_map` + OpenStreetMap (ฟรี) หรือ `google_maps_flutter` (ต้องมี billing) หมุดจำนวนมากควรทำ clustering
8. **Push Notification** – Realtime listener ทำงานตอนเปิดแอปเท่านั้น ใช้ **FCM** (ในตัว Firebase) แจ้งผู้ใช้เมื่อสถานะเปลี่ยนตอนปิดแอป และแจ้ง Admin เมื่อมีเคส urgent โดยส่งจาก Cloud Functions
9. **Admin เป็นแอปเดียวกันหรือแยก?** – เริ่มด้วยแอปเดียวกันแยกด้วย Custom Claim ได้ ระยะยาวควรทำ Admin เป็น Flutter Web เพราะ Dashboard/กรองข้อมูล/แผนที่ใช้จอใหญ่สะดวกกว่า (Firebase Hosting ใช้โฮสต์ได้)
10. **กัน spam / ความเป็นส่วนตัว** – จำกัดจำนวนรายงานต่อผู้ใช้ต่อวัน (นับใน Cloud Function หรือใช้ rule ร่วมกับตัวนับ), ซ่อน `reporterId` จาก Feed (ใช้คอลเลกชัน `issues_feed`), ลบ EXIF/พิกัดในรูปต้นฉบับ, เพิ่มหน้า Privacy Policy / PDPA consent ตอนสมัคร และเปิด **App Check** กันบอท/แอปปลอมเรียก backend
11. **Sentiment** – ให้ Gemini ตอบเป็น JSON ตายตัว (`sentiment`, `is_urgent`, `reason`) ใน Firestore trigger `onFeedbackCreate` แล้วส่ง FCM / อีเมลแจ้งผู้บริหาร
12. **ระดับความเร่งด่วน** – ให้ AI เสนอระดับอัตโนมัติจากข้อความ/รูป (เช่น สายไฟขาด = high) ผู้ใช้แก้ไขได้
13. **ข้อจำกัดของ Firestore ที่ต้องรู้** – ไม่มี JOIN และไม่มี full-text search ในตัว (ค้นหาข้อความใน Admin Dashboard ต้องใช้ Algolia/Typesense หรือกรองฝั่งแอปกับชุดข้อมูลที่ดึงมาแล้ว) การกรองหลายเงื่อนไขต้องมี composite index และคิดเงินตามจำนวนการอ่าน/เขียนเอกสาร จึงควรใส่ `limit` + pagination ทุก query ของ Feed/Dashboard

---

## 11. สำหรับ AI Agent

เมื่อสร้างโปรเจกต์จากเอกสารนี้ ให้:
1. เริ่มจาก Phase 1 → 2 ตามลำดับ Roadmap อย่าข้ามไปทำ AI ก่อน
2. ใช้โครงสร้างโฟลเดอร์ในข้อ 7 และ data model ในข้อ 6 เป็นจุดตั้งต้น
3. ห้ามใส่ secret ลงใน repo (Gemini key, service account key)
4. ทุกคอลเลกชันและ Storage path ต้องมี Security Rules ก่อนใช้งานจริง (ค่าเริ่มต้นคือปฏิเสธทั้งหมด `allow ...: if false`) และห้ามปล่อยโหมด test (`if true`)
5. UI ข้อความภาษาไทยเป็นหลัก (เตรียม i18n ไว้ด้วย)
6. ห้ามแก้ `issues.status`, `reportCount`, `issues_feed`, `updates`, `followers` ตรง ๆ จากแอป ให้เรียก callable Functions (`adminUpdateStatus`, `followIssue`, `reopenIssue`) และแก้ rules/index ผ่านไฟล์ใน repo (`firestore.rules`, `firestore.indexes.json`, `storage.rules`) เท่านั้น
7. Feed และ Map อ่านจากคอลเลกชัน `issues_feed` (ไม่มี `reporterId`) ส่วนหน้าประวัติอ่านจาก `issues` โดยกรอง `reporterId == uid`
8. เปิด Emulator Suite ทดสอบ rules ทุกครั้งก่อน deploy

---

## License

[TODO] เลือก License
