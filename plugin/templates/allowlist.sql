-- Allowlist for single-user / small-team private apps.
-- Drop into supabase/migrations/<timestamp>_allowlist.sql and run `bunx supabase db push`.
-- The skill should replace the placeholder emails below with the user's real list before saving.

-- 1. Table holding the emails permitted to sign in.
create table if not exists public.allowed_emails (
  email text primary key,
  note text,
  added_at timestamptz not null default now()
);

alter table public.allowed_emails enable row level security;

-- Service role bypasses RLS; nobody else can read or write this table.
create policy "service role only"
  on public.allowed_emails
  for all
  using (false)
  with check (false);

-- 2. Auth hook that blocks sign-up / sign-in for emails not on the list.
-- Supabase calls this via the "Send email hook" / "Before user created" auth hook.
-- See: https://supabase.com/docs/guides/auth/auth-hooks
create or replace function public.enforce_allowlist()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
begin
  if not exists (
    select 1 from public.allowed_emails
    where lower(email) = lower(new.email)
  ) then
    raise exception 'email_not_allowed' using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_allowlist_trigger on auth.users;
create trigger enforce_allowlist_trigger
  before insert on auth.users
  for each row
  execute function public.enforce_allowlist();

-- 3. Seed the owner's email(s). The skill replaces this list with real values.
insert into public.allowed_emails (email, note) values
  ('OWNER_EMAIL@example.com', 'owner')
on conflict (email) do nothing;
