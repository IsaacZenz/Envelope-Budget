-- Envelope Budget migration: bill envelopes
-- Run ONCE in Supabase: SQL Editor > New query > paste > Run.
-- Safe to run again (it skips anything that already exists). It doesn't touch existing data.
-- Needs migration-goals-and-order.sql first (bills reuse goal_cents as the bill amount).
--
-- categories.is_bill : true = a bill envelope. Its bill amount lives in goal_cents.
-- transactions.bill  : marks the spend that paid a bill.
--                      'paid'  = the envelope shows Paid (and is locked) until you Reset it.
--                      'reset' = an old payment, kept in History, that no longer counts as Paid.
--                      Deleting the payment transaction un-marks Paid automatically.

alter table public.categories
  add column if not exists is_bill boolean not null default false;

alter table public.transactions
  add column if not exists bill text;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'categories_bill_amount_check') then
    alter table public.categories
      add constraint categories_bill_amount_check check (not is_bill or goal_cents is not null);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'transactions_bill_check') then
    alter table public.transactions
      add constraint transactions_bill_check check (bill is null or (bill in ('paid', 'reset') and type = 'spend'));
  end if;
end $$;

-- Make the API see the new columns right away
notify pgrst, 'reload schema';
