[README.md](https://github.com/user-attachments/files/33063207/README.md)
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
| Local DB (Offline-first & Cache) | เลือก 1 ตัว: Drift / Isar / Hive (ดูข้อเสนอแนะข้อ 10) |
| AI Engine | Google **Gemini API** |
| Backend / Database | **Supabase** (PostgreSQL) |
| Authentication | Supabase Auth |
| File Storage | Supabase Storage Bucket |
| Realtime | Supabase Realtime |
| Dev / Self-host | **Docker** + Docker Compose (รัน Supabase backend ในเครื่อง) |

---

## 2. ผู้ใช้งานและสิทธิ์ (Roles)

| Role | สิทธิ์ |
|---|---|
| `user` (ประชาชน) | แจ้งปัญหา, ดู Feed สาธารณะ, ดูแผนที่, ดูประวัติและติดตามสถานะของตัวเอง, ให้คะแนน, ขอเปิดเรื่องซ้ำ, กด +1 |
| `admin` (เจ้าหน้าที่) | ดูปัญหาทั้งหมด, ค้นหา/กรอง, ดูแผนที่รวม, เปลี่ยนสถานะ, บันทึกหมายเหตุ, แนบรูปหลังแก้ไข, ดูผล Sentiment |

การบังคับสิทธิ์ทำที่ฐานข้อมูลด้วย **Row Level Security (RLS)** ไม่ใช่แค่ซ่อนปุ่มใน UI

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
- แสดงหมุดปัญหารอบตัวตามพิกัด GPS ปัจจุบันของผู้ใช้
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

## 6. Data Model (ร่างเริ่มต้นสำหรับ PostgreSQL / Supabase)

> **Source of truth คือ [`supabase/migrations/`](supabase/migrations/)** (schema + RLS + RPC + Storage policy) — SQL ด้านล่างเป็นภาพรวมเพื่ออ่านเท่านั้น
> ที่ต่างจากร่างนี้: มี `lat`/`lng` (generated), view `issues_feed` (ไม่มี `reporter_id`), และ RPC `admin_update_status`, `follow_issue`, `reopen_issue`, `nearby_issues` สำหรับงานที่ผู้ใช้ไม่ควรแก้ตารางตรง ๆ

```sql
create extension if not exists postgis;

-- ผู้ใช้ (ผูกกับ auth.users)
create table profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text,
  role text not null default 'user' check (role in ('user','admin')),
  created_at timestamptz default now()
);

create table categories (
  id serial primary key,
  code text unique not null,      -- electric, water, road, waste, other
  name_th text not null
);

create table issues (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references profiles(id),
  category_id int references categories(id),
  title text not null,
  description text,
  urgency text check (urgency in ('low','medium','high')) default 'medium',
  status text check (status in ('pending','in_progress','resolved')) default 'pending',
  location geography(point, 4326) not null,
  address_text text,
  report_count int default 1,         -- จำนวนผู้แจ้ง (รวม +1)
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index on issues using gist (location);

create table issue_images (
  id uuid primary key default gen_random_uuid(),
  issue_id uuid references issues(id) on delete cascade,
  storage_path text not null,
  kind text check (kind in ('report','resolution','reopen')) default 'report'
);

-- ผู้ที่กด +1 (กันกดซ้ำคนเดิม)
create table issue_followers (
  issue_id uuid references issues(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  primary key (issue_id, user_id)
);

-- Timeline / Log การเปลี่ยนสถานะ
create table issue_updates (
  id uuid primary key default gen_random_uuid(),
  issue_id uuid references issues(id) on delete cascade,
  actor_id uuid references profiles(id),
  status text,
  note text,
  created_at timestamptz default now()
);

create table feedback (
  id uuid primary key default gen_random_uuid(),
  issue_id uuid references issues(id) on delete cascade,
  user_id uuid references profiles(id),
  rating int check (rating between 1 and 5),
  tags text[],
  comment text,
  sentiment text,             -- positive / neutral / negative
  is_urgent boolean default false,
  created_at timestamptz default now()
);
```

**RLS (แนวทาง)**
- `issues`: ทุกคนที่ล็อกอิน `select` ได้ (สำหรับ Feed/Map) แต่ view ที่ส่งให้ client **ต้องไม่เปิดเผย `reporter_id`**
- `issues` insert: เฉพาะเจ้าของ (`reporter_id = auth.uid()`)
- `issues.status` / `issue_updates` update: เฉพาะ `role = 'admin'`
- `feedback`: เจ้าของ insert/select ของตัวเอง, admin select ทั้งหมด
- Storage: ผู้ใช้อัปโหลดเข้าโฟลเดอร์ตัวเอง, `resolution` อัปโหลดได้เฉพาะ admin

---

## 7. สถาปัตยกรรมแนะนำ

```
Flutter App ──► Supabase (Auth / Postgres+PostGIS / Storage / Realtime)
     │                      │
     │                      └─► Edge Functions ──► Gemini API
     └─► Local DB (cache + offline queue) ◄── sync เมื่อมีเน็ต
```

- **Offline-first**: บันทึกรายงานลง Local DB ก่อน แล้ว sync ขึ้น Supabase เมื่อมีอินเทอร์เน็ต
- **Realtime**: subscribe ตาราง `issues` / `issue_updates` เพื่ออัปเดตสถานะบนหน้าจอผู้ใช้ทันที
- **AI**: เรียก Gemini ผ่าน Supabase Edge Function ไม่เรียกตรงจากแอป (ดูข้อ 10)

### โครงสร้าง Repository

```
Bok-mai-mobile/
├── lib/                    # Flutter app (ดูด้านล่าง)
├── supabase/
│   ├── migrations/         # schema + RLS + RPC + storage (SQL)
│   ├── seed.sql            # ข้อมูลเริ่มต้น (หมวดหมู่)
│   └── functions/          # Edge Functions (เรียก Gemini) [TODO]
├── scripts/
│   └── selfhost.sh         # รัน backend ด้วย Docker Compose
├── docker/supabase/        # (สร้างอัตโนมัติโดย selfhost.sh, อยู่ใน .gitignore)
└── .env.example
```

### โครงสร้างโฟลเดอร์ Flutter (feature-first)

```
lib/
├── main.dart
├── core/            # theme, router, constants, utils, supabase client
├── data/            # local db, repositories, models
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

## 8. การติดตั้งและรันโปรเจกต์ (พร้อม Docker)

แอปมือถือ Flutter รันบนอีมูเลเตอร์/เครื่องจริง (ไม่รันใน Docker) ส่วนที่ใช้ **Docker** คือ **backend ทั้งชุด** (Postgres+PostGIS, Auth, Storage, Realtime, Studio, Edge Functions) เพื่อให้ใครก็ clone แล้วรันได้โดยไม่ต้องมีบัญชี Supabase Cloud

### สิ่งที่ต้องมี
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (มี Docker Compose v2) — แนะนำ RAM ว่างอย่างน้อย 4 GB
- [Flutter SDK](https://docs.flutter.dev/get-started/install), `git`, `openssl`
- (Windows) ใช้ WSL2 หรือ Git Bash รันสคริปต์

### วิธี A — Docker Compose (self-host) · ทำตามนี้ได้เลย

```bash
git clone https://github.com/SpriteUm/Bok-mai-mobile.git
cd Bok-mai-mobile

./scripts/selfhost.sh up      # ครั้งแรกใช้เวลาหลายนาที (ดึง image)
```

สคริปต์จะ: ดึง Docker Compose ทางการของ Supabase → สร้าง `.env` พร้อม secret ใหม่ → `docker compose up -d` → ลง `supabase/migrations/*.sql` และ `seed.sql` → พิมพ์ `SUPABASE_URL` / `SUPABASE_ANON_KEY` ให้

จากนั้นรันแอป:

```bash
cp .env.example .env          # ใส่ SUPABASE_URL และ SUPABASE_ANON_KEY ที่สคริปต์พิมพ์ให้
flutter pub get
flutter run
```

| คำสั่ง | ทำอะไร |
|---|---|
| `./scripts/selfhost.sh up` | ติดตั้ง + เริ่มระบบ + ลง schema |
| `./scripts/selfhost.sh down` | หยุด container (ข้อมูลยังอยู่) |
| `./scripts/selfhost.sh schema` | ลง migrations/seed ซ้ำ (หลังเพิ่มไฟล์ SQL ใหม่) |
| `./scripts/selfhost.sh reset` | ลบข้อมูลทั้งหมดแล้วเริ่มใหม่ |

เข้า Supabase Studio ที่ <http://localhost:8000> (user/password ดูที่ `DASHBOARD_USERNAME` / `DASHBOARD_PASSWORD` ใน `docker/supabase/.env`)

**ค่า `SUPABASE_URL` ตามอุปกรณ์**

| อุปกรณ์ | URL |
|---|---|
| iOS Simulator / Flutter Web / Desktop | `http://localhost:8000` |
| Android Emulator | `http://10.0.2.2:8000` |
| มือถือจริง (Wi-Fi เดียวกับคอมพิวเตอร์) | `http://<IP เครื่องคุณ>:8000` และอนุญาตพอร์ต 8000 ใน firewall |

> Android 9+ บล็อก HTTP แบบไม่เข้ารหัสโดยปริยาย ตอนพัฒนาให้เพิ่ม `android:usesCleartextTraffic="true"` ใน `AndroidManifest.xml` (เฉพาะ debug) ส่วน iOS ต้องตั้ง App Transport Security exception

### วิธี B — Supabase CLI (ทางเลือก สะดวกสำหรับนักพัฒนา)
CLI ใช้ Docker เบื้องหลังเช่นกัน และอ่าน `supabase/migrations/` ในโปรเจกต์นี้โดยตรง

```bash
npm i -g supabase            # หรือดู https://supabase.com/docs/guides/local-development
supabase init                # ครั้งแรกครั้งเดียว สร้าง supabase/config.toml แล้ว commit
supabase start               # พิมพ์ API URL และ anon key (URL ปกติ http://localhost:54321)
supabase db reset            # ลง migrations + seed.sql
```

### ตั้งให้ใครเป็น Admin
ผู้ใช้ทุกคนที่สมัครจะเป็น `user` เสมอ ให้ promote ผ่าน Studio → SQL Editor:

```sql
update public.profiles set role = 'admin'
where id = (select id from auth.users where email = 'admin@example.com');
```

### Environment variables

`.env.example`
```
SUPABASE_URL=http://10.0.2.2:8000
SUPABASE_ANON_KEY=
# ห้ามใส่ GEMINI_API_KEY ในแอป → เก็บเป็น Secret ของ Edge Function
```

เพิ่มใน `.gitignore`:
```
.env
docker/supabase/
supabase/.temp/
```

### Gemini (AI) ตอนรันบน Docker
ฟังก์ชัน AI จะอยู่ใน `supabase/functions/` แล้ว `selfhost.sh up` จะคัดลอกไปที่ container ให้ ใส่คีย์ Gemini ที่ `docker/supabase/.env` (ฝั่งเซิร์ฟเวอร์เท่านั้น) และส่งต่อเข้าบริการ `functions` ใน Compose ผ่าน `environment` [TODO: เพิ่ม Edge Function ตัวอย่าง]

### Troubleshooting
| อาการ | วิธีแก้ |
|---|---|
| พอร์ต 8000 ถูกใช้อยู่ | แก้ `API_GW_HTTP_PORT` (หรือ `KONG_HTTP_PORT`) ใน `docker/supabase/.env` แล้วอัปเดต `SUPABASE_URL` |
| แอปต่อ backend ไม่ได้บน Android | เช็คว่าใช้ `10.0.2.2` (emulator) หรือ IP เครื่องจริง และเปิด cleartext ตอน dev |
| `selfhost.sh` รอนานเกินไป | `cd docker/supabase && docker compose logs -f db storage` |
| Login ด้วย Google ไม่ผ่าน | ใน `docker/supabase/.env` ตั้ง `GOOGLE_ENABLED=true`, `GOOGLE_CLIENT_ID`, `GOOGLE_SECRET` และ uncomment บรรทัด `GOTRUE_EXTERNAL_GOOGLE_*` ในบริการ `auth` ของ `docker-compose.yml` แล้วเพิ่ม redirect URL ของแอป (ถ้าใช้ `signInWithIdToken` บนมือถือ ให้ดูตัวเลือก skip nonce check ในไฟล์เดียวกัน) |
| ต้องการเริ่มใหม่หมด | `./scripts/selfhost.sh reset` |

> ⚠️ ค่า default ของ Compose เหมาะสำหรับ **พัฒนา/ทดลองเท่านั้น** ก่อนขึ้น production ต้องเปลี่ยนรหัสผ่าน dashboard, ใส่ HTTPS/Reverse proxy, ตั้ง SMTP จริง, ปิดพอร์ต Postgres ไม่ให้เปิดสู่สาธารณะ และสำรองข้อมูล `docker/supabase/volumes/`

สิทธิ์ที่ต้องขอในแอป: Camera, Photos, Location (When In Use), Microphone

---

## 9. Roadmap (ลำดับการพัฒนาที่แนะนำ)

- [ ] **Phase 1 – Foundation**: ตั้งโปรเจกต์ Flutter, Supabase Auth, Role, DB + RLS
- [ ] **Phase 2 – Core MVP**: ฟอร์มแจ้งปัญหา (รูป + GPS), Home Feed, History + Realtime status
- [ ] **Phase 3 – Map & Admin**: Map View + filter, Admin Dashboard, เปลี่ยนสถานะ + รูปหลังแก้ไข
- [ ] **Phase 4 – AI**: Voice-to-Report, Duplicate Check, เบลอหน้า/ป้ายทะเบียน
- [ ] **Phase 5 – Feedback**: ให้คะแนน, Re-open, Sentiment Analysis + แจ้งเตือนผู้บริหาร
- [ ] **Phase 6 – Polish**: Offline-first sync, Push Notification, ทดสอบ, ขึ้น Store

---

## 10. ข้อเสนอแนะทางเทคนิค (Design Notes)

1. **อย่าเก็บ Gemini API Key ใน `.env` ของแอป** – ไฟล์ที่ bundle ไปกับแอปถูกแกะได้ ให้เรียก Gemini ผ่าน Supabase Edge Function แล้วเก็บคีย์เป็น Secret ฝั่งเซิร์ฟเวอร์
2. **เบลอใบหน้า/ป้ายทะเบียนทำบนเครื่อง** – Gemini วิเคราะห์ภาพได้แต่ไม่ได้ "แก้ไขภาพ" ใช้ Google ML Kit (Face Detection + Text Recognition สำหรับป้ายทะเบียน) แล้วเบลอด้วย Dart ก่อนอัปโหลด ข้อมูลส่วนบุคคลจะไม่ออกจากเครื่อง
3. **Duplicate Check ให้กรองด้วยพิกัดก่อน** – ใช้ PostGIS `ST_DWithin(location, point, 50)` หาปัญหาในรัศมี ~50 ม. หมวดเดียวกันที่ยังไม่ `resolved` แล้วค่อยส่งรูปคู่ที่ใกล้เคียงให้ Gemini เทียบ ประหยัดค่า API และแม่นยำกว่า
4. **Voice-to-Report** – ใช้ Gemini รับไฟล์เสียงโดยตรง (ถอดเสียง + สรุปหัวข้อใน call เดียว) หรือใช้ `speech_to_text` บนเครื่องแล้วให้ Gemini สรุป
5. **Local DB** – แนะนำ **Drift** (SQL, ดูแลต่อเนื่อง, เหมาะกับ sync) Isar เวอร์ชันหลักไม่ค่อยมีการอัปเดตแล้ว Hive เหมาะแค่ key-value/cache เล็กๆ
6. **State management** – แนะนำ **Riverpod** + `go_router`
7. **แผนที่** – `flutter_map` + OpenStreetMap (ฟรี) หรือ `google_maps_flutter` (ต้องมี billing) หมุดจำนวนมากควรทำ clustering
8. **Push Notification** – Realtime ใช้ได้ตอนเปิดแอปเท่านั้น ควรเพิ่ม Firebase Cloud Messaging เพื่อแจ้งผู้ใช้เมื่อสถานะเปลี่ยนตอนปิดแอป และแจ้ง Admin เมื่อมีเคส urgent
9. **Admin เป็นแอปเดียวกันหรือแยก?** – เริ่มด้วยแอปเดียวกันแยกด้วย role ได้ ระยะยาวควรทำ Admin เป็น Flutter Web เพราะ Dashboard/กรองข้อมูล/แผนที่ใช้จอใหญ่สะดวกกว่า
10. **กัน spam / ความเป็นส่วนตัว** – จำกัดจำนวนรายงานต่อผู้ใช้ต่อวัน, ซ่อน `reporter_id` จาก Feed, ลบ EXIF/พิกัดในรูปต้นฉบับ, เพิ่มหน้า Privacy Policy / PDPA consent ตอนสมัคร
11. **Sentiment** – ให้ Gemini ตอบเป็น JSON ตายตัว (`sentiment`, `is_urgent`, `reason`) แล้วใช้ Database Webhook / Edge Function ส่งแจ้งเตือนผู้บริหาร
12. **ระดับความเร่งด่วน** – ให้ AI เสนอระดับอัตโนมัติจากข้อความ/รูป (เช่น สายไฟขาด = high) ผู้ใช้แก้ไขได้

---

## 11. สำหรับ AI Agent

เมื่อสร้างโปรเจกต์จากเอกสารนี้ ให้:
1. เริ่มจาก Phase 1 → 2 ตามลำดับ Roadmap อย่าข้ามไปทำ AI ก่อน
2. ใช้โครงสร้างโฟลเดอร์ในข้อ 7 และ schema ในข้อ 6 เป็นจุดตั้งต้น
3. ห้ามใส่ secret ลงใน repo
4. ทุกตารางต้องเปิด RLS ก่อนใช้งานจริง
5. UI ข้อความภาษาไทยเป็นหลัก (เตรียม i18n ไว้ด้วย)
6. ห้ามแก้ตารางตรง ๆ จากแอปในกรณีที่มี RPC รองรับ (`admin_update_status`, `follow_issue`, `reopen_issue`) และแก้ schema ผ่านไฟล์ใหม่ใน `supabase/migrations/` เท่านั้น
7. Feed อ่านจาก view `issues_feed` (ไม่มี `reporter_id`) ส่วนหน้าประวัติอ่านจากตาราง `issues`

---

## License

[TODO] เลือก License
