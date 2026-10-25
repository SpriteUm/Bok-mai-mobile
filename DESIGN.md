---
version: 1.0.0
name: Bok Mai Design System
description: Material Design 3 and Adaptive Civic System for Bok Mai Mobile App
website: "https://bokmai.app"

colors:
  # Primary & Containers (Civic Trust Blue)
  primary: "#00629E"
  on-primary: "#FFFFFF"
  primary-container: "#CFE5FF"
  on-primary-container: "#001D34"

  # Secondary & Action (Responsive Teal)
  secondary: "#006A60"
  on-secondary: "#FFFFFF"
  secondary-container: "#73F8E7"
  on-secondary-container: "#00201D"

  # Tertiary / Civic Warm Accent
  tertiary: "#705D00"
  on-tertiary: "#FFFFFF"
  tertiary-container: "#FFE170"
  on-tertiary-container: "#221B00"

  # Neutral Surfaces & Backgrounds
  surface: "#FDFCFF"
  on-surface: "#1A1C1E"
  surface-variant: "#DEE3EB"
  on-surface-variant: "#42474E"
  surface-container-lowest: "#FFFFFF"
  surface-container-low: "#F7F9FD"
  surface-container: "#F1F4F9"
  surface-container-high: "#EBEFF4"
  surface-container-highest: "#E2E5EA"
  outline: "#73777F"
  outline-variant: "#C2C7CF"

  # Semantic Ticket Statuses
  status-pending: "#D97706"             # Amber / Warm Warning
  status-pending-container: "#FEF3C7"
  status-pending-on-container: "#78350F"

  status-in-progress: "#0284C7"         # Sky Blue / Active Processing
  status-in-progress-container: "#E0F2FE"
  status-in-progress-on-container: "#0369A1"

  status-resolved: "#16A34A"            # Civic Green / Success
  status-resolved-container: "#DCFCE7"
  status-resolved-on-container: "#15803D"

  # Error & Destructive
  error: "#BA1A1A"
  on-error: "#FFFFFF"
  error-container: "#FFDAD6"
  on-error-container: "#410002"

typography:
  display-large:
    fontFamily: "Prompt, system-ui, sans-serif"
    fontSize: 32px
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: 0px
  display-medium:
    fontFamily: "Prompt, system-ui, sans-serif"
    fontSize: 28px
    fontWeight: 700
    lineHeight: 1.28
    letterSpacing: 0px
  title-large:
    fontFamily: "Prompt, system-ui, sans-serif"
    fontSize: 22px
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: 0px
  title-medium:
    fontFamily: "Prompt, system-ui, sans-serif"
    fontSize: 16px
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: 0.15px
  body-large:
    fontFamily: "Sarabun, system-ui, sans-serif"
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.6
    letterSpacing: 0.5px
  body-medium:
    fontFamily: "Sarabun, system-ui, sans-serif"
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.6
    letterSpacing: 0.25px
  body-small:
    fontFamily: "Sarabun, system-ui, sans-serif"
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.55
    letterSpacing: 0.4px
  label-large:
    fontFamily: "Prompt, system-ui, sans-serif"
    fontSize: 14px
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: 0.1px
  label-medium:
    fontFamily: "Prompt, system-ui, sans-serif"
    fontSize: 12px
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: 0.5px
  label-small:
    fontFamily: "Prompt, system-ui, sans-serif"
    fontSize: 11px
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: 0.5px

rounded:
  none: "0px"
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "28px"
  full: "9999px"

spacing:
  xxs: "2px"
  xs: "4px"
  sm: "8px"
  md: "12px"
  base: "16px"
  lg: "20px"
  xl: "24px"
  xxl: "32px"
  section: "48px"

components:
  card-incident:
    backgroundColor: "{colors.surface-container-lowest}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.lg}"
    padding: "16px"
    border: "1px solid {colors.surface-container-highest}"
  card-incident-elevated:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.lg}"
    padding: "16px"
    elevation: "1"
  badge-status-pending:
    backgroundColor: "{colors.status-pending-container}"
    textColor: "{colors.status-pending-on-container}"
    typography: "{typography.label-medium}"
    rounded: "{rounded.full}"
    padding: "4px 10px"
    height: "24px"
  badge-status-in-progress:
    backgroundColor: "{colors.status-in-progress-container}"
    textColor: "{colors.status-in-progress-on-container}"
    typography: "{typography.label-medium}"
    rounded: "{rounded.full}"
    padding: "4px 10px"
    height: "24px"
  badge-status-resolved:
    backgroundColor: "{colors.status-resolved-container}"
    textColor: "{colors.status-resolved-on-container}"
    typography: "{typography.label-medium}"
    rounded: "{rounded.full}"
    padding: "4px 10px"
    height: "24px"
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-large}"
    rounded: "{rounded.full}"
    padding: "10px 24px"
    height: "48px"
  button-tonal:
    backgroundColor: "{colors.secondary-container}"
    textColor: "{colors.on-secondary-container}"
    typography: "{typography.label-large}"
    rounded: "{rounded.full}"
    padding: "10px 24px"
    height: "48px"
  button-outlined:
    backgroundColor: "transparent"
    textColor: "{colors.primary}"
    typography: "{typography.label-large}"
    rounded: "{rounded.full}"
    padding: "10px 24px"
    height: "48px"
    border: "1px solid {colors.outline}"
  fab-report:
    backgroundColor: "{colors.primary-container}"
    textColor: "{colors.on-primary-container}"
    typography: "{typography.label-large}"
    rounded: "{rounded.lg}"
    height: "56px"
    minWidth: "56px"
    padding: "16px"
    elevation: "3"
  input-field:
    backgroundColor: "{colors.surface-container-high}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-large}"
    rounded: "{rounded.xs}"
    padding: "12px 16px"
    minHeight: "56px"
  bottom-nav-bar:
    backgroundColor: "{colors.surface-container}"
    textColor: "{colors.on-surface-variant}"
    height: "80px"
---

## Overview

**Bok Mai (บอกไหม)** เป็นระบบออกแบบ UI/UX สำหรับแอปพลิเคชันแจ้งปัญหาสาธารณะบนมือถือ (Mobile Civic Engagement & Operations) ที่พัฒนาด้วย Flutter รองรับทั้ง Android และ iOS อย่างกลมกลืน (Adaptive Multi-Platform)

ระบบอ้างอิงตามข้อกำหนด **Material Design 3 (M3)** อย่างเคร่งครัด ผสานกับหลักการ **Usability & Accessibility สำหรับการใช้งานจริงนอกสถานที่ (Field Use)**:
1. **ออกแบบเพื่อความสะดวกและรวดเร็ว (Speed & Zero Friction):** รองรับการแจ้งเหตุฉับไวด้วยมือเดียวกลางแจ้ง ท่ามกลางแดดจ้า
2. **โปร่งใสและตรวจสอบได้ (Transparent & Trustworthy):** มี State Lifecycle ของปัญหาชัดเจน ให้ประชาชนและเจ้าหน้าที่เห็นสถานะเดียวกัน
3. **ปกป้องข้อมูลส่วนบุคคล (PDPA-first Privacy):** ฟีดสาธารณะไม่มีการเปิดเผยชื่อผู้แจ้ง หรือภาพใบหน้า/ป้ายทะเบียนที่ยังไม่เบลอ
4. **ความสมบูรณ์ของฟอนต์ภาษาไทย (Thai Typography-First):** ออกแบบ Line-height และ Type Scale ให้รองรับสระและวรรณยุกต์ไทยโดยเฉพาะ ป้องกันปัญหาสระบน-ล่างขาดหรือซ้อนทับ

---

## Colors

ระบบสีใช้ **Material Design 3 Tonal Color Roles** คำนึงถึง Contrast Ratio ตามมาตรฐาน WCAG AA (อย่างน้อย 4.5:1 สำหรับข้อความปกติ และ 3.0:1 สำหรับข้อความขนาดใหญ่หรือ UI Components):

### Primary & Container Roles (Civic Trust)
- **Primary** (`{colors.primary}` — `#00629E`): โทนน้ำเงินแห่งความไว้วางใจ ใช้กับ Primary Action, App Bar และจุดสำคัญ
- **On-Primary** (`{colors.on-primary}` — `#FFFFFF`): ข้อความและไอคอนบน Primary Color
- **Primary Container** (`{colors.primary-container}` — `#CFE5FF`): พื้นหลังปุ่ม FAB หรือส่วนเน้นย่อย
- **On-Primary Container** (`{colors.on-primary-container}` — `#001D34`): ข้อความบน Primary Container

### Secondary & Action Roles
- **Secondary** (`{colors.secondary}` — `#006A60`): โทนเขียวอมฟ้า Teal แสดงถึงการลงมือทำ การตอบสนอง
- **Secondary Container** (`{colors.secondary-container}` — `#73F8E7`): สำหรับ Tonal Chips, Filter Badges
- **On-Secondary Container** (`{colors.on-secondary-container}` — `#00201D`): ข้อความบน Secondary Container

### Surfaces & Backgrounds (Tonal Elevation)
M3 อาศัยการไล่ระดับ Tonal Surface แทนการใช้ Drop Shadow หนักๆ:
- **Surface** (`#FDFCFF`): พื้นผิวมาตรฐาน
- **Surface Container Lowest** (`#FFFFFF`): การ์ดข้อมูลใน Feed
- **Surface Container High / Highest** (`#EBEFF4` / `#E2E5EA`): ช่อง Input และ Dividers
- **On-Surface** (`#1A1C1E`): สีตัวหนังสือหลัก คอนทราสต์สูง อ่านง่ายกลางแจ้ง

### Semantic Ticket Statuses (สถานะงานสาธารณะ)
แต่ละสถานะมีชุดสี Container และ On-Container คู่กัน เพื่อให้ผู้ใช้แยกแยะได้ทันทีโดยไม่พึ่งพาสีเพียงอย่างเดียว:
- **Pending (รอดำเนินการ):** Amber (`#D97706` / Container `#FEF3C7` / Text `#78350F`) ควบคู่กับไอคอน `schedule`
- **In Progress (กำลังดำเนินการ):** Active Sky Blue (`#0284C7` / Container `#E0F2FE` / Text `#0369A1`) ควบคู่กับไอคอน `engineering` หรือ `build`
- **Resolved (แก้ไขแล้วเสร็จ):** Civic Green (`#16A34A` / Container `#DCFCE7` / Text `#15803D`) ควบคู่กับไอคอน `check_circle`

---

## Typography

ฟอนต์ในระบบจับคู่ระหว่าง **Prompt** (Modern Geometric สำหรับ Headings) และ **Sarabun** (Humanist Sans สำหรับ Body Copy) เพื่อความลงตัวทั้งภาษาไทยและอังกฤษ:

### Thai Typography Rules
- **Line Height:** ตั้งค่าขั้นต่ำที่ `1.55 – 1.6` สำหรับข้อความเนื้อหา (Body) เพื่อรองรับวรรณยุกต์ชั้นที่สอง (ไม้เอก, โท, ตรี, จัตวา) และสระบน-ล่าง (อุ, อู, อิ, อี) โดยไม่ถูกตัดขอบ
- **Dynamic Type Scale:** รองรับการปรับขนาดตัวอักษรของระบบมือถือ (Accessibility Text Scaling) ไม่กำหนดค่าเป็น Fixed Pixel แบบตายตัวในโค้ด Flutter

### Hierarchy Table

| Token | Size | Weight | Line Height | ฟอนต์ | การใช้งาน |
|---|---|---|---|---|---|
| `{typography.display-large}` | `32px` | 700 | 1.25 | Prompt | สรุปสถิติเด่น, หน้า Welcome |
| `{typography.display-medium}` | `28px` | 700 | 1.28 | Prompt | หัวข้อสำคัญของหน้าจอ |
| `{typography.title-large}` | `22px` | 600 | 1.30 | Prompt | หัวข้อหลักใน App Bar |
| `{typography.title-medium}` | `16px` | 600 | 1.35 | Prompt | หัวเรื่องการ์ดปัญหา (Card Title) |
| `{typography.body-large}` | `16px` | 400 | 1.60 | Sarabun | รายละเอียดปัญหา, กล่องกรอกข้อมูล |
| `{typography.body-medium}` | `14px` | 400 | 1.60 | Sarabun | ข้อความเนื้อหาทั่วไป, ที่อยู่ย่อ |
| `{typography.body-small}` | `12px` | 400 | 1.55 | Sarabun | เวลาที่แจ้ง, คำอธิบายประกอบ |
| `{typography.label-large}` | `14px` | 600 | 1.40 | Prompt | ตัวหนังสือบนปุ่ม (Buttons) |
| `{typography.label-medium}` | `12px` | 600 | 1.40 | Prompt | ป้ายสถานะ (Status Badges, Chips) |

---

## Layout

- **Spacing Grid:** ใช้ระบบ Grid ฐาน 4dp/8dp (`4px`, `8px`, `12px`, `16px`, `24px`, `32px`)
- **Safe Area & Window Insets:** ปรับตาม Dynamic Island / Notch ด้านบน และ Home Indicator / System Navigation ด้านล่างอย่างเคร่งครัด
- **Mobile Feed Density:** ความกว้างขอบจอซ้าย-ขวาอยู่ที่ `16px` เพื่อให้ได้พื้นที่แสดงภาพปัญหาและแผนที่ย่ออย่างสมบูรณ์

---

## Elevation & Depth

ใช้หลักการ **Material 3 Tonal Elevation** ควบคู่กับเงาที่นุ่มนวล (Soft Ambient Shadow):
- **Level 0 (Flat):** พื้นหลังจอและ Bottom App Bar
- **Level 1 (Card/List item):** การ์ดแจ้งเหตุใน Feed (`elevation: 1` หรือ Subtle Border `1px`)
- **Level 2 (Filter Sheet / Dialog):** Bottom Sheet ตัวกรอง และหน้าต่างยืนยัน
- **Level 3 (FAB):** ปุ่ม Floating Action Button สำหรับ "แจ้งเหตุใหม่" ลอยเด่นเหนือเนื้อหา

---

## Shapes

- **Inputs / TextFields:** `{rounded.xs}` (`4px`) ถึง `{rounded.sm}` (`8px`) ตามสไตล์ M3 Filled Input
- **Cards & Containers:** `{rounded.lg}` (`16px`) ให้ความรู้สึกเป็นมิตรและทันสมัย
- **Buttons & Chips:** `{rounded.full}` (`9999px`) สไตล์ Full Stadium Pill ตามมาตรฐาน M3
- **Floating Action Button:** `{rounded.lg}` (`16px`) สไตล์ M3 Squircle FAB

---

## Components

### 1. Feed Incident Card (`card-incident`)
- โครงสร้าง: ภาพถ่ายปัญหา (อัตราส่วน 16:9) ด้านบน พร้อม Badge สถานะมุมขวาบน
- ส่วนเนื้อหา: หัวข้อปัญหา (`title-medium`), รายละเอียดสั้น (`body-medium`), แผนที่ย่อ/พิกัด (`body-small`)
- แถบความคืบหน้าด้านล่าง: ปุ่มกด **+1 ติดตามเรื่องนี้** และตัวเลขนับผู้ร่วมแจ้ง

### 2. Status Badge (`badge-status-*`)
- แคปซูลขนาดกะทัดรัด ความสูงอย่างน้อย `24px`
- มีทั้งไอคอนขนาดเล็ก (14px) และข้อความภาษาไทย (เช่น "⏳ รอดำเนินการ", "⚙️ กำลังดำเนินการ", "✅ แก้ไขแล้ว")

### 3. Smart Report Floating Action Button (`fab-report`)
- วางตำแหน่งด้านขวาล่าง หรือตรงกลาง Bottom Navigation Bar
- ไอคอนกล้อง/เพิ่มรูปภาพ พร้อมข้อความ "แจ้งปัญหา" รองรับการกดด้วยนิ้วโป้งมือข้างเดียว

### 4. Interactive Bottom Navigation Bar (`bottom-nav-bar`)
- ความสูง `80px` ตามสเปก M3
- 4 รายการหลัก:
  1. `หน้าแรก / ฟีด` (Feed)
  2. `แผนที่รวม` (Map View)
  3. `ประวัติของฉัน` (My History)
  4. `บัญชี / การตั้งค่า` (Profile)

---

## Usability Testing & Ergonomics Checklist

เพื่อให้ UI ผ่านเกณฑ์ Usability Testing บนมือถือจริง ทุกหน้าจอต้องผ่านเกณฑ์ต่อไปนี้:

1. **Touch Target Size:** จุดสัมผัสทุกจุด (Buttons, IconButtons, Chips) ต้องมีขนาด **ไม่ต่ำกว่า 48×48 dp** แม้ว่าขนาดภาพไอคอนจะอยู่ที่ 24dp ก็ตาม (ขยาย Tap Target ด้วย padding)
2. **One-Handed Thumb Reachability:** การกระทำสำคัญ (ปุ่มแจ้งเหตุ, ตัวกรองด่วน, การนำทางหลัก) อยู่ในช่วงครึ่งล่างของหน้าจอเพื่อให้กดได้สะดวกขณะเดิน
3. **Outdoor Sunlight Readability:** คอนทราสต์สีของข้อความสำคัญเกิน 4.5:1 เสมอเพื่อให้อ่านได้ชัดเจนแม้อยู่กลางแดด
4. **Accessible Status Communication:** ไม่สื่อสารสถานะด้วยสีเพียงอย่างเดียว ต้องมี Label ข้อความภาษาไทยและไอคอนกำกับเสมอ สำหรับผู้ใช้งานที่มีภาวะตาบอดสี (Color Vision Deficiency)
5. **Clear Empty & Loading States:** มี Skeleton Loading ชัดเจนเมื่อโหลดรูปหรือข้อมูลช้าเนื่องจากสัญญาณอินเทอร์เน็ตภาคสนาม

---

## Do's and Don'ts

### Do
- **Do** ใช้ Line-height ไม่ต่ำกว่า `1.55` สำหรับข้อความภาษาไทยเพื่อป้องกันสระจม
- **Do** ให้ความสำคัญกับการเบลอใบหน้าและป้ายทะเบียนก่อนแสดงรูปใน Feed
- **Do** แสดงปุ่ม "+1 ติดตามเรื่องนี้" แทนการสร้างรายงานใหม่เมื่อตรวจพบปัญหาซ้ำในพิกัดเดียวกัน

### Don't
- **Don't** ทำปุ่มหรือจุดสัมผัสขนาดเล็กกว่า `48×48 dp`
- **Don't** นำชื่อ-นามสกุล หรือข้อมูลส่วนตัวของผู้แจ้งมาแสดงใน Public Feed
- **Don't** พึ่งพาเงาสีดำเข้ม (Hard Shadows) ในการแบ่งเลเยอร์ ให้ใช้โทนสี Tonal Surface ของ M3 แทน
