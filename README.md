# cafe_app

A new Flutter project.

## Development

Run with Supabase keys (optional at this stage):

```bash
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

CI runs analyze, tests, and a debug build via GitHub Actions.

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
