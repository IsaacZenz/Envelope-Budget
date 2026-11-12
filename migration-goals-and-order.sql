-- Envelope Budget migration: savings goals + custom category order
-- Run ONCE in Supabase: SQL Editor > New query > paste > Run.
-- Safe to run again (it skips columns that already exist). It doesn't touch existing data.
--
-- goal_cents : savings goal target in whole cents ($500.00 = 50000). Empty = regular category.
-- sort_order : your drag-and-drop position (0 = top). Empty = never reordered; sorts by creation time.

alter table public.categories
  add column if not exists goal_cents bigint
    constraint categories_goal_cents_check check (goal_cents is null or (goal_cents > 0 and goal_cents <= 999999999)),
  add column if not exists sort_order integer
    constraint categories_sort_order_check check (sort_order is null or sort_order >= 0);

-- Make the API see the new columns right away
notify pgrst, 'reload schema';
