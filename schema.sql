-- ============================================================
-- ALPHA STRATEGY — Supabase schema
-- Run this once in your Supabase project's SQL editor
-- (Project → SQL Editor → New query → paste → Run)
-- ============================================================

-- 1) Pending join requests from the public signup form.
--    Anyone can INSERT (submit the form). Only admins can read/manage.
create table if not exists signup_requests (
  id bigint generated always as identity primary key,
  name text not null,
  email text not null,
  monthly_amount numeric not null default 50,
  wallet text,
  risk_ack boolean not null default false,
  status text not null default 'pending', -- pending | approved | rejected
  created_at timestamptz not null default now()
);

-- 2) Approved participants. Admin creates these (usually by approving
--    a signup_request). Public can read (dashboard lookup by id),
--    only admins can write.
create table if not exists participants (
  id text primary key,                 -- e.g. 'AS-1001'
  name text not null,
  email text,
  joined_date date not null default current_date,
  status text not null default 'Active',
  monthly_amount numeric not null default 50,
  created_at timestamptz not null default now()
);

-- 3) Contribution history — one row per monthly payment.
create table if not exists contributions (
  id bigint generated always as identity primary key,
  participant_id text not null references participants(id) on delete cascade,
  date date not null default current_date,
  amount numeric not null,
  note text default 'Monthly DCA',
  created_at timestamptz not null default now()
);

-- 4) Quarterly / latest snapshot of holdings + PnL per participant.
--    Admin updates this manually (or via a script hitting the Bybit API).
--    Dashboard reads the latest row per participant.
create table if not exists participant_stats (
  id bigint generated always as identity primary key,
  participant_id text not null references participants(id) on delete cascade,
  quarter text not null,               -- e.g. 'Q3 2026'
  btc numeric not null default 0,
  btc_avg_cost numeric not null default 0,
  altcoins_usd numeric not null default 0,
  leverage_usd numeric not null default 0,
  realized_pnl numeric not null default 0,
  unrealized_pnl numeric not null default 0,
  net_value numeric not null default 0,
  borrowing_exposure numeric not null default 0,
  updated_at timestamptz not null default now()
);

-- 5) Reserve-wide summary shown on every dashboard (single row, id=1).
create table if not exists reserve_summary (
  id int primary key default 1,
  total_participants int not null default 0,
  total_btc numeric not null default 0,
  total_value_usd numeric not null default 0,
  quarter text not null default 'Q3 2026',
  phase text not null default 'Accumulation',
  updated_at timestamptz not null default now(),
  constraint single_row check (id = 1)
);
insert into reserve_summary (id) values (1) on conflict (id) do nothing;

-- ============================================================
-- ROW LEVEL SECURITY
-- Public (anon key, used by the website) can:
--   - insert into signup_requests (submit the join form)
--   - select from participants, contributions, participant_stats,
--     reserve_summary (so the dashboard can look someone up)
-- Only authenticated admins (you, logged in via Supabase Auth) can:
--   - read signup_requests
--   - write to participants, contributions, participant_stats,
--     reserve_summary, and update signup_requests
-- ============================================================

alter table signup_requests enable row level security;
alter table participants enable row level security;
alter table contributions enable row level security;
alter table participant_stats enable row level security;
alter table reserve_summary enable row level security;

-- signup_requests
create policy "public can submit signup requests"
  on signup_requests for insert
  to anon
  with check (true);

create policy "admins can read signup requests"
  on signup_requests for select
  to authenticated
  using (true);

create policy "admins can update signup requests"
  on signup_requests for update
  to authenticated
  using (true);

-- participants
create policy "public can read participants"
  on participants for select
  to anon, authenticated
  using (true);

create policy "admins can write participants"
  on participants for all
  to authenticated
  using (true)
  with check (true);

-- contributions
create policy "public can read contributions"
  on contributions for select
  to anon, authenticated
  using (true);

create policy "admins can write contributions"
  on contributions for all
  to authenticated
  using (true)
  with check (true);

-- participant_stats
create policy "public can read participant stats"
  on participant_stats for select
  to anon, authenticated
  using (true);

create policy "admins can write participant stats"
  on participant_stats for all
  to authenticated
  using (true)
  with check (true);

-- reserve_summary
create policy "public can read reserve summary"
  on reserve_summary for select
  to anon, authenticated
  using (true);

create policy "admins can write reserve summary"
  on reserve_summary for all
  to authenticated
  using (true)
  with check (true);
