-- Ledger version 2: adds an optional note (up to 250 characters) to each entry,
-- and lets entries and categories be marked as income instead of expense.
-- Paste into the Supabase SQL Editor and run once. Existing rows are kept and
-- are all treated as expenses with no note. Safe to run again.
--
-- Supabase will show its "destructive operations" warning because of the
-- "drop index" line. That line removes only a uniqueness rule, which the next
-- statement replaces with one that allows the same name in both lists.

alter table public.expenses
  add column if not exists note text check (char_length(note) <= 250);

alter table public.expenses
  add column if not exists kind text not null default 'expense' check (kind in ('expense', 'income'));

alter table public.categories
  add column if not exists kind text not null default 'expense' check (kind in ('expense', 'income'));

drop index if exists public.categories_user_name_key;
create unique index if not exists categories_user_kind_name_key
  on public.categories (user_id, kind, lower(name));
