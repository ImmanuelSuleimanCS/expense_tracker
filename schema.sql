-- Ledger: budget tracker schema for Supabase.
-- Paste this whole file into the Supabase SQL Editor and run it once.
-- It is safe to run again; nothing is dropped except the two policies it recreates.

-- Your editable lists of categories, one for expenses and one for income.
create table if not exists public.categories (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name        text not null check (length(trim(name)) > 0),
  kind        text not null default 'expense' check (kind in ('expense', 'income')),
  created_at  timestamptz not null default now()
);

-- One category name per user and list, ignoring upper/lower case.
create unique index if not exists categories_user_kind_name_key
  on public.categories (user_id, kind, lower(name));

-- Every entry you log, expense or income (the table keeps its original name). The category is stored as plain text on purpose:
-- if the category is later deleted, the app shows the expense under "Default",
-- and if you add the category back, the history returns to it.
create table if not exists public.expenses (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  category    text not null default 'Default',
  amount      numeric(12,2) not null check (amount > 0),
  note        text check (char_length(note) <= 250),
  kind        text not null default 'expense' check (kind in ('expense', 'income')),
  logged_at   timestamptz not null default now()
);

-- A database created with version 1 is upgraded with migration_v2.sql instead.

create index if not exists expenses_user_logged_idx
  on public.expenses (user_id, logged_at desc);

-- Row-level security: a signed-in user can only see and change their own rows.
-- This is what makes it safe for the app's key to sit in a public web page.
alter table public.categories enable row level security;
alter table public.expenses   enable row level security;

drop policy if exists "own categories" on public.categories;
create policy "own categories" on public.categories
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "own expenses" on public.expenses;
create policy "own expenses" on public.expenses
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.categories to authenticated;
grant select, insert, update, delete on public.expenses   to authenticated;
