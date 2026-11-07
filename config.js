// Supabase project settings for Envelope Budget.
// Find both values in Supabase: Project Settings > API (or Data API).
// The anon / publishable key is meant to be public: row-level security in
// supabase/schema.sql keeps each person's budget private.
// NEVER put the service_role / secret key here.
window.BUDGET_CONFIG = {
  supabaseUrl: 'https://YOUR-PROJECT-ID.supabase.co',
  supabaseAnonKey: 'YOUR-ANON-OR-PUBLISHABLE-KEY'
};
