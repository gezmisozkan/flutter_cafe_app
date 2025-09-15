# Cafe App – Comprehensive TODO

## M0 – Repo & Tooling
- [x] Finalize M0 setup: packages, lint (very_good_analysis), CI, i18n scaffold
- [ ] Design app theme palette and typography tokens

## M1 – Navigation, Auth (in-memory first)
- [x] Implement ShellRoute bottom tabs (Home, Order, My Card, Store, More)
- [x] Create Home screen: campaigns list stub + quick links
- [x] Implement in-memory auth mock (sign up/in/out) + session state
- [x] Build Auth screens (email/password) with validation
- [x] Add Profile screen (name, phone, favorite drink) using local store

## M2 – Loyalty (in-memory)
- [x] Add loyalty in-memory store: wallet balance + transactions list
- [x] Create My Card screen: QR (user_id), balance, earn/redeem UI
- [x] Implement Redeem flow UI with rewards list (mock seed)

## M3 – Menu, Cart, Orders (local-only)
- [x] Menu: categories grid and items list (mock data)
- [x] Menu item detail: image, price, free-text notes
- [x] Cart provider (local): add/update/remove, compute totals
- [x] Order confirm screen: ASAP/+10 min, place order (local queue)
- [ ] Orders list/history for user (local)

## M4 – Store Info
- [x] Store Info screen: address, hours, phone, map deeplink

## M5 – Admin (mock)
- [x] Admin Panel gate (role flag) visible only to admins
- [x] Admin Dashboard: counts (users, orders today, points today) mock
- [x] Admin Scan & Earn: simulate scan input, add points
- [x] Admin Orders: list and update status (Pending/Ready/Completed)
- [x] Admin Menu CRUD forms (mock persistence)
- [x] Admin Campaigns: create text campaigns shown on Home

## M6 – Polishing & QA
- [x] Offline UX: cache menu locally; queue cart until online (mock)
- [x] Error handling: toasts with retry; empty states
- [x] Smoke tests: auth, place order, redeem, admin earn (mock)
- [ ] QA polish: icons, splash, copy, light/dark review
- [x] Release build docs: Android APK and iOS guide

## M7 – Backend Swap (Supabase)
- [ ] Switch data layer to Supabase repositories (behind interfaces)
- [x] Supabase SQL: tables, RLS, seed and README instructions

Notes:
- **Status: 25/28 completed (89%)** - MVP is fully functional!
- Remaining: theme design, orders history UI, QA polish, Supabase integration
- All core features working: auth, loyalty, menu, cart, orders, admin panel
- Keep UI-first using in-memory stores; swap to Supabase under repository interfaces later.



-----

Finalize M0 setup: packages, lint, CI, i18n scaffold
Design app theme palette and typography tokens
Implement ShellRoute bottom tabs (Home, Order, My Card, Store, More)
Create Home screen: campaigns list stub + quick links
Implement in-memory auth mock (sign up/in/out) + session state
Build Auth screens (email/password) with validation
Add Profile screen (name, phone, favorite drink) using local store
Create My Card screen: QR (user_id), balance, earn/redeem UI
Add loyalty in-memory store: wallet balance + transactions list
Implement Redeem flow UI with rewards list (mock seed)
Menu: categories grid and items list (mock data)
Menu item detail: image, price, free-text notes
Cart provider (local): add/update/remove, compute totals
Order confirm screen: ASAP/+10 min, place order (local queue)
Orders list/history for user (local)
Store Info screen: address, hours, phone, map deeplink
Admin Panel gate (role flag) visible only to admins
Admin Dashboard: counts (users, orders today, points today) mock
Admin Scan & Earn: simulate scan input, add points
Admin Orders: list and update status (Pending/Ready/Completed)
Admin Menu CRUD forms (mock persistence)
Admin Campaigns: create text campaigns shown on Home
Offline UX: cache menu locally; queue cart until online (mock)
Error handling: toasts with retry; empty states
Smoke tests: auth, place order, redeem, admin earn (mock)
Switch data layer to Supabase repositories (behind interfaces)
Supabase SQL: tables, RLS, seed and README instructions
QA polish: icons, splash, copy, light/dark review
Release build docs: Android APK and iOS guide
Implement My Card screen with QR + mock points provider
