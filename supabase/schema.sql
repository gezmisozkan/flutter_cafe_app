-- Basic schema for cafe loyalty + ordering (mock-ready)

create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  name text,
  phone text,
  favorite_drink text,
  created_at timestamp with time zone default now()
);

create table if not exists loyalty_wallets (
  user_id uuid primary key references profiles(id) on delete cascade,
  points integer not null default 0,
  updated_at timestamp with time zone default now()
);

create table if not exists loyalty_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  delta integer not null,
  reason text not null,
  created_at timestamp with time zone default now()
);

create table if not exists menu_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sort_order integer not null default 0
);

create table if not exists menu_items (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references menu_categories(id) on delete cascade,
  name text not null,
  price_cents integer not null,
  image_url text,
  is_active boolean not null default true
);

create type order_status as enum ('pending','ready','completed','canceled');

create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  status order_status not null default 'pending',
  pickup_minutes_from_now integer not null default 0,
  total_cents integer not null,
  created_at timestamp with time zone default now()
);

create table if not exists order_items (
  order_id uuid references orders(id) on delete cascade,
  menu_item_id uuid references menu_items(id),
  name text not null,
  qty integer not null,
  price_cents_snapshot integer not null,
  note text,
  primary key (order_id, menu_item_id, name)
);

-- Simple seeds
insert into menu_categories (id, name, sort_order) values
  (gen_random_uuid(), 'Coffee', 1),
  (gen_random_uuid(), 'Tea', 2),
  (gen_random_uuid(), 'Snacks', 3)
on conflict do nothing;

-- RLS example (enable as needed)
-- alter table profiles enable row level security;
-- create policy "users can view own profile" on profiles for select using (auth.uid() = id);

