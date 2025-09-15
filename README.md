# cafe_app

A new Flutter project.

## Development

Run with Supabase keys (optional at this stage):

```bash
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

CI runs analyze, tests, and a debug build via GitHub Actions.

## App overview

Cafe Loyalty + Ordering (in-memory MVP) with Riverpod and GoRouter. It includes:
- Home, Order, My Card (loyalty), Store, More/Profile tabs
- Local cart and orders queue (mock), loyalty balance with QR and rewards
- Admin Panel (mock) for manual earn, orders status, and campaigns
- Offline menu cache via `shared_preferences`

### Usage
1. Run the app: `flutter run`
2. Go to More → Sign In (any email/password). Admin creds: `admin@admin.com` / `admin`
3. Order: Home → Order → add an item → View Cart → Place order
4. Loyalty: Home → My Card → Earn +10, or Admin Panel → add points
5. Redeem: My Card → Redeem → pick a reward when you have enough points

## Release builds

### Android APK
- Run: `flutter build apk --release`
- Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS (guide)
1. Open `ios/Runner.xcworkspace` in Xcode
2. Set a unique bundle id and signing team
3. Product → Archive, then Distribute App (TestFlight/App Store)

Optional env defines (for backend later):
`flutter run --dart-define=SUPABASE_URL= --dart-define=SUPABASE_ANON_KEY=`
