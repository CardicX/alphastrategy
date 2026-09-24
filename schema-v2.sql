-- ============================================================
-- ALPHA STRATEGY — schema v2
-- Run this once in Supabase SQL Editor (after schema.sql).
-- Adds: withdrawal requests, OTC deposit requests, support tickets.
-- ============================================================

-- 1) Withdrawal requests — participant asks to pull funds out.
--    Admin reviews and marks approved/rejected/completed.
create table if not exists withdrawal_requests (
  id bigint generated always as identity primary key,
  participant_id text not null references participants(id) on delete cascade,
  currency text not null default 'BTC',      -- BTC | USDT | ETH
  amount numeric not null,
  destination text not null,                 -- wallet address to send to
  note text,
  status text not null default 'pending',    -- pending | approved | rejected | completed
  admin_note text,
  created_at timestamptz not null default now(),
  processed_at timestamptz
);

-- 2) OTC deposit requests — participant wants to deposit a larger
--    amount off the standard QR flow (wire, negotiated rate, etc).
--    Admin contacts them and marks the outcome.
create table if not exists otc_requests (
  id bigint generated always as identity primary key,
  participant_id text not null references participants(id) on delete cascade,
  currency text not null default 'USDT',
  amount numeric not null,
  contact text not null,                     -- best way to reach them (telegram/email)
  note text,
  status text not null default 'pending',    -- pending | contacted | completed | cancelled
  admin_note text,
  created_at timestamptz not null default now()
);

-- 3) Support tickets.
create table if not exists support_tickets (
  id bigint generated always as identity primary key,
  participant_id text references participants(id) on delete set null,
  name text not null,
  email text not null,
  subject text not null,
  message text not null,
  status text not null default 'open',       -- open | replied | closed
  admin_reply text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- These three tables carry more sensitive data than the rest of
-- the site (withdrawal destinations, contact info, messages) —
-- so unlike participants/contributions, public can INSERT their
-- own request but can NOT read anyone's, including their own,
-- back through the anon key. Only authenticated admins can read
-- and update. requests.html shows a simple "submitted" confirmation
-- rather than reading the row back.
-- ============================================================

alter table withdrawal_requests enable row level security;
alter table otc_requests enable row level security;
alter table support_tickets enable row level security;

-- withdrawal_requests
create policy "public can submit withdrawal requests"
  on withdrawal_requests for insert to anon with check (true);
create policy "admins can read withdrawal requests"
  on withdrawal_requests for select to authenticated using (true);
create policy "admins can update withdrawal requests"
  on withdrawal_requests for update to authenticated using (true) with check (true);
create policy "admins can delete withdrawal requests"
  on withdrawal_requests for delete to authenticated using (true);

-- otc_requests
create policy "public can submit otc requests"
  on otc_requests for insert to anon with check (true);
create policy "admins can read otc requests"
  on otc_requests for select to authenticated using (true);
create policy "admins can update otc requests"
  on otc_requests for update to authenticated using (true) with check (true);
create policy "admins can delete otc requests"
  on otc_requests for delete to authenticated using (true);

-- support_tickets
create policy "public can submit support tickets"
  on support_tickets for insert to anon with check (true);
create policy "admins can read support tickets"
  on support_tickets for select to authenticated using (true);
create policy "admins can update support tickets"
  on support_tickets for update to authenticated using (true) with check (true);
create policy "admins can delete support tickets"
  on support_tickets for delete to authenticated using (true);
