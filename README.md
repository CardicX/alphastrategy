# Alpha Strategy — Setup Guide

Static site (no build step) + Supabase for data. Deploys anywhere that serves
plain HTML — GitHub Pages, Vercel, Netlify, Cloudflare Pages, etc.

## 1. Create your Supabase project
1. Go to https://supabase.com → New project.
2. Once it's ready, open **SQL Editor** → New query.
3. Paste the entire contents of `schema.sql` from this repo and run it.
   This creates all tables and the security rules (RLS) that let the
   public website read/write only what it should.

## 2. Get your API keys
Project → **Settings → API**:
- **Project URL**
- **anon public** key

Open `supabase-config.js` and replace the two placeholder values:

```js
const SUPABASE_URL = "https://YOUR-PROJECT-REF.supabase.co";
const SUPABASE_ANON_KEY = "YOUR-ANON-PUBLIC-KEY";
```

This key is meant to be public — it only allows what the RLS policies in
`schema.sql` permit (public read, public insert only on `signup_requests`,
everything else requires an authenticated admin).

## 3. Create your admin login
Project → **Authentication → Users → Add user** (email + password).
This is the account you'll use to log into `admin.html`.
You can add more admin users the same way later.

## 4. How the pieces connect

| Page | What it does |
|---|---|
| `index.html` | Marketing / strategy explainer. No backend calls. |
| `signup.html` | Public form → inserts a row into `signup_requests`. |
| `admin.html` | Login required. Approve requests (creates a real `participants` row + ID like `AS-1001`), log monthly contributions, update each participant's quarterly stats snapshot, update the reserve-wide summary. |
| `dashboard.html` | Participant enters their ID → reads live from `participants`, `contributions`, `participant_stats`, `reserve_summary`. |

Nothing here touches Bybit directly — that's intentional. Keep entering
figures manually in `admin.html` for now (safest, no exchange API keys in
a browser-facing app), or later write a small script/cron job that pulls
from the Bybit API and writes into `participant_stats` /
`reserve_summary` using Supabase's service-role key **on a server**,
never in the website's client code.

## 5. Deploy
Any static host works since there's no server code:

- **GitHub Pages**: push this folder to a repo, enable Pages on the
  `main` branch (or `/docs`), done.
- **Vercel / Netlify**: import the repo, no build command needed, output
  directory = repo root.

## 6. Local testing before you deploy
From this folder:

```bash
python3 -m http.server 8000
```

Then open `http://localhost:8000`.

## Notes / next steps
- Add real email notifications (e.g. Supabase Edge Function + Resend/SendGrid)
  so participants know when they're approved.
- Consider a "my ID" magic-link email instead of asking people to remember
  `AS-XXXX`.
- When you're ready to go public/formalize, revisit the legal/compliance
  side before onboarding participants outside your existing trusted group —
  pooling outside contributions into a managed strategy is regulated in
  most places.
