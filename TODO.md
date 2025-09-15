# Cafe App – Comprehensive TODO

## M0 – Repo & Tooling
- [x] Finalize M0 setup: packages, lint (very_good_analysis), CI, i18n scaffold
- [ ] Design app theme palette and typography tokens

## M1 – Navigation, Auth (in-memory first)
- [x] Implement ShellRoute bottom tabs (Home, Order, My Card, Store, More)
- [ ] Create Home screen: campaigns list stub + quick links
- [ ] Implement in-memory auth mock (sign up/in/out) + session state
- [ ] Build Auth screens (email/password) with validation
- [ ] Add Profile screen (name, phone, favorite drink) using local store

## M2 – Loyalty (in-memory)
- [ ] Add loyalty in-memory store: wallet balance + transactions list
- [x] Create My Card screen: QR (user_id), balance, earn/redeem UI  (in progress)
- [ ] Implement Redeem flow UI with rewards list (mock seed)

## M3 – Menu, Cart, Orders (local-only)
- [ ] Menu: categories grid and items list (mock data)
- [ ] Menu item detail: image, price, free-text notes
- [ ] Cart provider (local): add/update/remove, compute totals
- [ ] Order confirm screen: ASAP/+10 min, place order (local queue)
- [ ] Orders list/history for user (local)

## M4 – Store Info
- [ ] Store Info screen: address, hours, phone, map deeplink

## M5 – Admin (mock)
- [ ] Admin Panel gate (role flag) visible only to admins
- [ ] Admin Dashboard: counts (users, orders today, points today) mock
- [ ] Admin Scan & Earn: simulate scan input, add points
- [ ] Admin Orders: list and update status (Pending/Ready/Completed)
- [ ] Admin Menu CRUD forms (mock persistence)
- [ ] Admin Campaigns: create text campaigns shown on Home

## M6 – Polishing & QA
- [ ] Offline UX: cache menu locally; queue cart until online (mock)
- [ ] Error handling: toasts with retry; empty states
- [ ] Smoke tests: auth, place order, redeem, admin earn (mock)
- [ ] QA polish: icons, splash, copy, light/dark review
- [ ] Release build docs: Android APK and iOS guide

## M7 – Backend Swap (Supabase)
- [ ] Switch data layer to Supabase repositories (behind interfaces)
- [ ] Supabase SQL: tables, RLS, seed and README instructions

Notes:
- Current focus: My Card screen (QR + mock points), then Loyalty store and Redeem UI.
- Keep UI-first using in-memory stores; swap to Supabase under repository interfaces later.
