-- Envelope Budget: Supabase schema for go-live
-- Run once in Supabase: SQL Editor > New query > paste > Run.
-- Mirrors the prototype's data model exactly, so the page's storage layer
-- swaps from the prototype store to Supabase without changing any money logic.
--
-- Money is always stored as whole cents (bigint). $11.11 = 1111.
-- Balances are never stored; they are derived from transactions, so deleting
-- a transaction undoes it exactly.
--
-- Rules (same as the prototype):
--   income : total += amount
--   assign : category += amount                      (Ready to Assign goes down)
--   spend  : total -= amount; category -= amount; category += covered
--            (covered = shortfall pulled from Ready to Assign on overspend)
--   move   : from category -= amount; to category += amount
--            (to_category_id null = back to Ready to Assign)
--   Ready to Assign = total - sum(balances of non-deleted categories)

create table public.categories (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name        text not null check (char_length(name) between 1 and 40),
  created_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

-- No two active categories with the same name (case-insensitive) per user
create unique index categories_active_name_uniq
  on public.categories (user_id, lower(name)) where deleted_at is null;

create table public.transactions (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null default auth.uid() references auth.users(id) on delete cascade,
  type            text not null check (type in ('income', 'assign', 'spend', 'move')),
  amount_cents    bigint not null check (amount_cents > 0),
  category_id     uuid references public.categories(id),
  to_category_id  uuid references public.categories(id),
  covered_cents   bigint not null default 0 check (covered_cents >= 0 and covered_cents <= amount_cents),
  note            text check (char_length(note) <= 80),
  tx_date         date not null default current_date,
  created_at      timestamptz not null default now(),
  constraint tx_shape check (
    (type = 'income' and category_id is null and to_category_id is null and covered_cents = 0) or
    (type = 'assign' and category_id is not null and to_category_id is null and covered_cents = 0) or
    (type = 'spend'  and category_id is not null and to_category_id is null) or
    (type = 'move'   and category_id is not null and covered_cents = 0
                     and (to_category_id is null or to_category_id <> category_id))
  )
);

-- History view: newest first, paged 25 at a time
create index transactions_user_history_idx
  on public.transactions (user_id, tx_date desc, created_at desc);

-- Row-level security: each user sees and changes only their own budget
alter table public.categories enable row level security;
alter table public.transactions enable row level security;

create policy "own categories" on public.categories
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "own transactions" on public.transactions
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Per-category balances (security_invoker so RLS applies to the caller)
create view public.category_balances with (security_invoker = true) as
select
  c.id, c.user_id, c.name, c.created_at, c.deleted_at,
  coalesce(sum(
    case
      when t.type = 'assign' and t.category_id = c.id then t.amount_cents
      when t.type = 'spend'  and t.category_id = c.id then -t.amount_cents + t.covered_cents
      when t.type = 'move'   and t.category_id = c.id then -t.amount_cents
      when t.type = 'move'   and t.to_category_id = c.id then t.amount_cents
      else 0
    end), 0)::bigint as balance_cents
from public.categories c
left join public.transactions t
  on t.user_id = c.user_id and (t.category_id = c.id or t.to_category_id = c.id)
group by c.id;

-- Top-of-page totals: Total balance and Ready to Assign
create view public.budget_summary with (security_invoker = true) as
with tot as (
  select user_id,
         sum(case type when 'income' then amount_cents when 'spend' then -amount_cents else 0 end)::bigint as total_cents
  from public.transactions group by user_id
), assigned as (
  select user_id, sum(balance_cents)::bigint as assigned_cents
  from public.category_balances where deleted_at is null group by user_id
)
select tot.user_id,
       tot.total_cents,
       tot.total_cents - coalesce(assigned.assigned_cents, 0) as ready_to_assign_cents
from tot left join assigned using (user_id);

-- Let signed-in users reach the tables through the API (RLS still limits them to their own rows)
grant select, insert, update, delete on public.categories, public.transactions to authenticated;
grant select on public.category_balances, public.budget_summary to authenticated;

-- Live updates between your phone and computer
alter publication supabase_realtime add table public.categories, public.transactions;

-- Test oracle for QA: should always return zero rows.
-- Total = Ready to Assign + sum(active category balances)
-- select s.user_id from public.budget_summary s
-- join (select user_id, sum(balance_cents) b from public.category_balances
--       where deleted_at is null group by user_id) cb using (user_id)
-- where s.total_cents <> s.ready_to_assign_cents + cb.b;
