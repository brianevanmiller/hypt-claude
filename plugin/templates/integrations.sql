-- Per-user OAuth integration tokens for connecting to external services
-- (Google, Notion, Slack, Airtable, etc.).
-- Drop into supabase/migrations/<timestamp>_integrations.sql and run `bunx supabase db push`.
--
-- Storage notes:
-- - Supabase encrypts the underlying disk at rest, but rows are readable in
--   plaintext to anyone with DB access (service role, dashboard SQL editor).
-- - For column-level encryption, wrap access_token / refresh_token with
--   pgsodium (https://supabase.com/docs/guides/database/extensions/pgsodium)
--   or Supabase Vault before storing. Not enabled here by default.
-- - Always read these rows server-side (service role) and never expose
--   access_token to the browser.

create table if not exists public.integrations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null,
  access_token text not null,
  refresh_token text,
  expires_at timestamptz,
  scope text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, provider)
);

create index if not exists integrations_user_provider_idx
  on public.integrations (user_id, provider);

alter table public.integrations enable row level security;

-- A user can only see / modify their own integration rows.
create policy "users read own integrations"
  on public.integrations
  for select
  using (auth.uid() = user_id);

create policy "users insert own integrations"
  on public.integrations
  for insert
  with check (auth.uid() = user_id);

create policy "users update own integrations"
  on public.integrations
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "users delete own integrations"
  on public.integrations
  for delete
  using (auth.uid() = user_id);

-- Auto-touch updated_at on row changes.
create or replace function public.touch_integrations_updated_at()
  returns trigger
  language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists integrations_touch_updated_at on public.integrations;
create trigger integrations_touch_updated_at
  before update on public.integrations
  for each row
  execute function public.touch_integrations_updated_at();
