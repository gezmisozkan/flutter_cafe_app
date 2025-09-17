# Supabase Setup

1) Create a Supabase project and note your project URL and anon key.

2) Run migrations:

Option A – SQL editor:
- Open Supabase SQL editor and execute the contents of `schema.sql`.

Option B – CLI (recommended to track migrations):
- Install supabase CLI and run inside project root:
```
supabase db push --db-url "postgresql://postgres:<password>@<host>:5432/postgres"
```

3) (Optional) Enable RLS and policies (see commented examples in `schema.sql`).

4) Configure app environment:
```
flutter run \
  --dart-define=SUPABASE_URL=YOUR_PROJECT_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

What’s wired now:
- Campaigns use Supabase automatically when `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set. Otherwise fallbacks to in-memory.

Next:
- Swap auth, menu, orders, loyalty to Supabase under repository interfaces.

