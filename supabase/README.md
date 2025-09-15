# Supabase Setup (Optional for later)

1. Create a new project in Supabase.
2. Open SQL editor and run `schema.sql` from this folder.
3. Configure RLS policies as needed (examples commented at bottom of schema).
4. Create a service role key and anon key.

App configuration for local runs (optional for now):

```
flutter run \
  --dart-define=SUPABASE_URL=YOUR_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Next steps (not implemented yet):
- Implement `CampaignsRepository` Supabase implementation
- Implement repositories for menu, orders, loyalty
- Wire providers based on flavor/env

