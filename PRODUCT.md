# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Stack

Flutter (Dart) targeting Android and iOS, backed by Supabase (PostgreSQL, Auth, Storage, Realtime) and Google Gemini API for AI features.

## Users

- **Citizens (ประชาชน):** Residents reporting community infrastructure and public problems (electricity, water, roads, waste, etc.), tracking real-time resolution progress, and upvoting (+1) duplicate issues.
- **Municipal Field Officers / Admins (เจ้าหน้าที่):** Field technicians and local administrators tracking incidents, updating statuses, posting resolution photo evidence, and reviewing citizen feedback.

## Product Purpose

Bok Mai (บอกไหม) streamlines citizen reporting of civic and public utility issues with zero friction. It bridges the gap between public grievances and municipality response through AI-assisted reporting (voice, photo, duplicate detection), real-time status transparency, and location-aware feeds.

## Positioning

Unlike generic municipal hotlines or bureaucratic web forms, Bok Mai offers a modern civic feed ("Facebook-style" public feed with strict privacy/anonymity) with AI-powered duplicate grouping (+1 tracking), automatic face/plate privacy blurring, and transparent resolution timeline tracking.

## Operating Context

- Mobile devices on the move (field reports in direct sunlight, shaky hands, varied network conditions).
- Offline-first caching for submitting tickets and checking status in low-connectivity areas.
- Thai municipal governance and neighborhood community reporting.

## Capabilities and Constraints

- **AI-Powered Reporting:** Voice-to-text reporting, automated categorization, and AI duplicate detection based on GPS proximity and image matching.
- **Privacy & PDPA:** Automatic face and vehicle license plate blurring before media upload; anonymous public feed (no names, no public comments, no public likes).
- **Incident Lifecycle:** State machine transitions: `pending` -> `in_progress` -> `resolved` (with reopen capability upon unsatisfactory resolution).
- **Real-time Map & List Views:** Interactive map with proximity filtering and incident category filters.
- **Multilingual / Thai Localization:** Thai (ภาษาไทย) as the primary user-facing language; clean typography suitable for Thai scripts.

## Brand Commitments

- **Name:** Bok Mai (บอกไหม)
- **Tone & Voice:** Trustworthy, responsive, approachable, civic-minded, and transparent.

## Evidence on Hand

- Project specification and requirements detailed in [README.md](file:///c:/Users/Nawapon/Desktop/Work/Kmitl/P3/P3T1/Miniproject/Bok-mai-mobile/README.md).
- Fresh Flutter project structure ready for UI architecture and screen implementation.

## Product Principles

1. **Effortless & Accessible Reporting:** Filing an issue should take seconds—supported by smart defaults, voice input, and GPS auto-tagging.
2. **Transparent Accountability:** Users always know who is handling their issue, current progress, and photo-verified outcomes.
3. **Respect for Privacy (PDPA-first):** Public utility reports must never compromise citizen identities or bystanders' privacy.
4. **Resilient in the Field:** Must function gracefully with intermittent network connectivity and varying device capabilities.

## Accessibility & Inclusion

- High contrast readability for outdoor/daylight usage.
- Sizable tap targets suitable for one-handed outdoor reporting.
- Thai font rendering with appropriate line-height to prevent tone mark clipping (e.g., Sarabun, Prompt, or Sukhumvit styles).

