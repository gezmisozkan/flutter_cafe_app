# Cafe App — Frontend TODOs (MVP)

## Sprint 1 — Foundation & Catalog
- [x] Add Firebase packages (core, auth, firestore, functions, messaging, storage, remote_config, app_check)
- [x] App theme (light/dark), typography, spacing tokens
- [x] Routing with go_router (tabs + routes)
- [x] Firebase bootstrap (Core, App Check, Remote Config, Messaging permissions)
- [x] Register background messaging handler
- [ ] Remote Config: surface maintenance banner in app shell
- [ ] Home: Greeting, "Order again" recent orders, nearest store card, promo banner (stub → link)
- [ ] Order tab: categories + items from Firestore (read path, offline cache)
- [ ] Product detail: base price + modifiers UI & live price
- [x] Cart UI (local) — minimal
- [ ] Cart in Firestore (carts/{uid}) — basic sync

## Sprint 2 — Checkout & Orders
- [ ] createPaymentIntent callable integration (stub ok)
- [ ] Provider SDK confirm (Stripe/iyzico) handoff (stub ok)
- [ ] confirmCheckout callable → order create → navigate to tracker
- [ ] Order tracker: listen to orders/{id}

## Sprint 3 — Loyalty & Promos
- [ ] Read wallet (loyalty_wallets/{uid}) + progress
- [ ] Rewards list, toggle/apply to cart
- [ ] applyPromo callable (preview)

## Sprint 4 — KDS & Admin Lite
- [ ] KDS web (columns + transitions + sound)
- [ ] Admin CRUD for stores/categories/products/modifiers (Storage uploads)

## Sprint 5 — Polish
- [ ] Animations & skeletons
- [ ] Offline banners, error toasts, global error surface
- [ ] Receipt PDF open from Storage
- [ ] Indices and basic emulator rule tests

---

## Immediate Steps
1) Save FCM device token after login to `users/{uid}/tokens/{tid}` and keep in sync
2) Show maintenance banner via Remote Config (read-only)
3) Add basic Firestore reads for categories/products (offline enabled)
4) Implement product detail modifiers and price recompute (client-only)
5) Persist cart to Firestore (single active cart per user)

## Firebase Backend (MVP)
- [ ] Project setup: Enable Auth (phone+email), Firestore, Functions (2nd gen), Storage, FCM, Remote Config, App Check; add iOS/Android app IDs; upload APNs key
- [ ] Remote Config defaults: earn_rate, maintenance flag, promo toggles
- [ ] Firestore structure:
  - [ ] users/{uid}: profile, roles; mirror loyalty points
  - [ ] users/{uid}/tokens/{tid}: device tokens
  - [ ] stores/{storeId}: name, address, lat/lon, hours, is_open, pickup_prep_minutes, busy_state
  - [ ] categories/{categoryId}: name, sort, active, storeIds
  - [ ] products/{productId}: name, desc, image_url, base_price, active, categoryId
  - [ ] products/{id}/modifiers/{groupId}
  - [ ] products/{id}/modifiers/{groupId}/options/{optionId}
  - [ ] products/{id}/store_overrides/{storeId}: price/active/sold_out
  - [ ] carts/{uid}: store_id, pickup_at, reward_applied, promo_code, items[], totals_cache
  - [ ] orders/{orderId}: user_id, store_id, status, pickup_code, created_at, paid_provider, cart_snapshot, reward_used_points?
  - [ ] orders/{orderId}/status_events/{eventId}
  - [ ] loyalty_wallets/{uid} and loyalty_wallets/{uid}/ledger/{id}
  - [ ] promos/{promoId}
  - [ ] reports_daily/{YYYYMMDD} (optional)
- [ ] Indexes:
  - [ ] orders: (store_id ASC, status ASC, created_at DESC)
  - [ ] orders: (user_id ASC, created_at DESC)
  - [ ] products: (categoryId ASC, active DESC)
  - [ ] promos: single field on code (or doc ID as code)
- [ ] Security rules:
  - [ ] Users read their own carts and orders only
  - [ ] Staff (claim + store) can read/update orders for their store
  - [ ] Admins can edit catalog, stores, promos
  - [ ] Users can write own users/{uid}/tokens/*
  - [ ] Loyalty writes via Functions only
  - [ ] Storage: products/* write admin; receipts/{orderId}.pdf readable by owner, staff for store, or admin
- [ ] Auth & Roles:
  - [ ] Phone OTP + optional email/password
  - [ ] Callable assignRole({ uid, role, storeIds? }) sets custom claims
  - [ ] Client forces token refresh after claim changes
- [ ] Cloud Functions (2nd gen):
  - [ ] createPaymentIntent({ cart, store_id, use_reward?, promo_code? }) → returns client_secret/params
  - [ ] confirmCheckout({ intent_id }) → creates orders/*, pickup code, status_events(received), clears cart, sends FCM
  - [ ] applyPromo({ code, cart }) → { discount_amount, reason? }
  - [ ] assignRole({ uid, role, storeIds? }) (admin-only)
  - [ ] Webhook /webhooks/stripe or /webhooks/iyzico → verify signature, mark payment definitive, idempotent
  - [ ] Trigger onOrderStatusChange: push updates; on ready → credit loyalty (transaction)
  - [ ] Trigger onOrderIssue: process refund; negative loyalty ledger; user push
  - [ ] Scheduler dailyReportJob → aggregate yesterday sales into reports_daily
- [ ] FCM:
  - [x] Save device tokens post-auth (client)
  - [ ] Push events: order_received, order_in_prep, order_ready, refund_issued
  - [ ] Staff topic: store_{storeId} for KDS devices
- [ ] Storage:
  - [ ] Product image uploads (client resize or CF resizer)
  - [ ] Generate and upload receipts PDFs to receipts/{orderId}.pdf
