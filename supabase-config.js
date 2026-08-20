/* ============================================================
   SUPABASE CONFIG
   Fill these in from your Supabase project:
   Project Settings → API → Project URL / anon public key
   The anon key is safe to expose in client code — it's what
   Row Level Security (in schema.sql) is designed to gate.
   ============================================================ */

const SUPABASE_URL = "https://YOUR-PROJECT-REF.supabase.co";
const SUPABASE_ANON_KEY = "YOUR-ANON-PUBLIC-KEY";

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
