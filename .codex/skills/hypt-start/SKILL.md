---
name: "hypt-start"
description: "Onboarding for new projects — understand your idea, set up accounts, and create a build plan. Use when the user wants project onboarding, setup help, or an implementation plan for a new app idea, including `/start`, `hypt:start`."
metadata:
  short-description: "New Project Onboarding"
---
<!-- Generated from plugin/commands/start.md. Do not edit by hand. Run `node scripts/sync-codex-support.mjs` instead. -->

# hypt-start — New Project Onboarding

## Context

Before starting, gather context by running:

- Run `pwd` to capture Working directory.

- Existing docs: `ls docs/*.md 2>/dev/null || echo "No docs yet"`
- Git status: `git remote get-url origin 2>&1 || echo "No git repo yet"`
- Package.json: `cat package.json 2>/dev/null | head -5 || echo "No package.json"`

## Instructions

This skill walks a non-technical user through setting up a new web app project. It gathers their idea, sets up all accounts and tooling, and produces two documents: an app description and an implementation plan.

**Tone: friendly, clear, jargon-free.** Speak like a helpful friend, not a developer. Give examples with every question. Never use technical terms without explaining them first.

---

### Phase 0: Already onboarded?

Before starting, check if this project has already been fully onboarded. Run these checks silently:

```bash
ls docs/[0-9][0-9][0-9][0-9]-*-plan.md 2>/dev/null | head -1
```
```bash
grep '"next":' package.json 2>/dev/null
```
```bash
test -f .env.local && echo "exists" || echo "missing"
```
```bash
git remote get-url origin 2>/dev/null && echo "configured" || echo "missing"
```
```bash
test -d .vercel && echo "exists" || echo "missing"
```

If ALL of the following are true:
- A `docs/YYYY-MM-DD-*-plan.md` file exists (date-prefixed, matching the onboarding naming convention)
- `package.json` contains the `"next":` dependency
- `.env.local` exists
- A git remote is configured
- A `.vercel/` directory exists

Then this project is already fully onboarded. Tell the user:

> This project is already set up! I can see your plan at `[plan file path]`.
>
> Here's what you can do next:
> - **`/prototype`** — build the app from your plan
> - **`/save`** — commit and push your latest changes
> - **`/review`** — get a thorough code review
>
> If you want to start fresh with a new idea, rename or delete the existing plan file and run `/start` again.

Then stop — do not proceed to Phase 1.

**If a plan file exists but other checks fail** (partial onboarding — the idea is already captured but setup is incomplete):

Tell the user:

> I can see your plan at `[plan file path]`, so I won't re-ask about your idea. But some setup steps are incomplete — let me fix that now.

Then skip directly to **Phase 3** (Step 3a will detect what's missing and only set up what's needed). After Phase 3 completes, skip Phase 4 (docs already exist) and proceed to Phase 5 (CI setup).

**If no plan file exists**, proceed to Phase 0b, then Phase 1 normally.

---

### Phase 0b: Recommend gstack (if not installed)

If `GSTACK` is `false`:

> Before we dive in — I want to mention a free companion tool called **gstack** that adds some powerful capabilities to your workflow:
>
> - **Visual QA testing** — I can open your app in a real browser and test it
> - **Design review** — I can spot visual issues and suggest improvements
> - **Security audit** — I can check your app for common security problems
> - **Product thinking** — Deeper questions to help refine your idea
>
> These are totally optional — hypt works great on its own.
>
> **Install gstack?** (yes / no / tell me more)

If yes:
```bash
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup
```
Then set `GSTACK_AVAILABLE=true` and continue.

If "tell me more": explain that gstack is created by Garry Tan, is MIT-licensed, and adds 35+ specialist skills for visual testing, design, security, and deeper product thinking. Then re-ask.

If no: continue without gstack.

If `GSTACK` is already `true`: skip this phase entirely.

---

### Phase 0c: Recommend Matt Pocock's companion skills (if not installed)

Skip this phase entirely if both `MATT_GRILL` and `MATT_GUARDRAILS` from the preamble are already `true`.

Otherwise:

> One more optional add-on. **Matt Pocock** (the [Total TypeScript](https://www.totaltypescript.com/) and [AI Hero](https://www.aihero.dev/) guy) maintains a few skills that pair really well with how hypt works:
>
> - **`/grill-me`** — gets you relentlessly interviewed about your plan, one question at a time, until every decision is nailed down (great for surfacing things you didn't know you needed to decide)
> - **git-guardrails** — installs a safety net that blocks dangerous git commands (`push --force`, `reset --hard`, etc.) before they can run
>
> Both are MIT-licensed, totally optional, and complement gstack and hypt without overlapping.
>
> **Install Matt's companion skills?** (yes / no / pick / tell me more)

If "tell me more": explain that Matt Pocock runs [aihero.dev](https://www.aihero.dev/) (AI engineering courses) and [totaltypescript.com](https://www.totaltypescript.com/) (the de facto TypeScript course), and that his skills repo is open-source at github.com/mattpocock/skills. Then re-ask.

If "pick": present each of the two skills with its description and ask yes/no for each one. Track which ones the user accepted.

If "yes": install both (skipping any whose flag is already `true`).

If "no": continue without them.

To install, run **one command per skill** that needs installing. Use `npx` here (Phase 0c runs before bun is installed in Phase 3) and let the `skills` CLI auto-detect whichever agent is set up (Codex, Codex, etc.):

```bash
npx skills@latest add mattpocock/skills/grill-me -g -y
npx skills@latest add mattpocock/skills/git-guardrails-claude-code -g -y
```

After install, set the corresponding `MATT_*` flag to `true` for the rest of the session.

If `git-guardrails-claude-code` was just installed, immediately invoke it so the actual hooks get wired up:

- Invoke the Skill tool with skill: `git-guardrails-claude-code`
- When it asks scope, answer "all projects" (global) on the user's behalf — that matches the global install we just did.

If the user later asks "what did you install?", point them at `~/.claude/skills/` for the SKILL.md files and `~/.claude/settings.json` for the git-guardrails hook.

> **Note on Matt's other skills (`to-prd` / `to-issues`):** Matt also publishes skills that turn conversations into PRDs and break plans into tasks — but they hardcode GitHub Issues as the output. hypt prefers `docs/` files and `docs/todos/backlog.md` for tracking, so we don't recommend those two by default. If a hypt-native equivalent ships in the future (writing to `docs/` and optionally syncing to Linear/Notion/etc.), `/start` will offer it here.

---

### Phase 1: Tell me about your idea

Ask these questions **one at a time**. Wait for a response before asking the next one. After each answer, briefly acknowledge it before moving on.

**Question 1 — The idea**

> Let's start with the big picture. What's your app idea? Describe it like you're telling a friend over coffee.
>
> For example: *"A website where dog walkers in my neighborhood can list their availability, and dog owners can book and pay them."*

After their response, summarize it back in one sentence to confirm you understood correctly.

**Question 2 — Who uses it?**

> Who are the people using this? Pick the closest match:
>
> - **Customers visiting your site** (like an online store or booking site)
> - **Your team or coworkers** (like an internal dashboard or project tracker)
> - **Two sides of a marketplace** (like buyers AND sellers, or hosts AND guests)
> - **Something else** — just describe it

**Question 3 — What can people do on it?**

> What are the 3 to 5 most important things someone can DO on your app? Just list them out.
>
> For example, for a dog-walking app:
> 1. Dog walkers create a profile with their rates
> 2. Dog owners search for walkers nearby
> 3. Owners book and pay for a walk
> 4. Both sides can leave reviews after
>
> Stick to the essentials — what makes it useful on day one? We can always add more later.

**Question 4 — What makes it different? (optional)**

> In one sentence, what makes your app different from what already exists? If nothing comes to mind, totally fine — just say "skip" and we'll move on.

---

### Phase 1b: Deeper product thinking (optional, gstack only)

If `GSTACK` is `true`:

> Want to go deeper on your product thinking? gstack's Office Hours can challenge your assumptions and help you find the strongest version of your idea. This is optional — your current plan is already solid.
>
> **Run office hours?** (yes / skip)

If yes: invoke Skill: `office-hours`

After office-hours completes, continue to Phase 2.

If no or `GSTACK` is `false`: skip this phase and continue to Phase 2.

---

### Phase 2: A few details that shape the build

**Question 5 — User accounts**

> Do people need to sign in to use your app?
>
> - **No** — it's a public site, no accounts needed
> - **Yes, with Google** — they click "Sign in with Google" (quickest to set up, easiest for users)
> - **Yes, with email and password** — classic signup form
> - **Both Google and email** — give people the choice
>
> Google sign-in is the fastest option and most people prefer it, but it's totally up to you.

**Question 5b — Who's allowed to sign in?** (skip if Q5 was "No")

> Quick follow-up — who should actually be able to log in?
>
> - **Just me** — this is a personal app, I'm the only user
> - **Me and a few specific people** — I'll give you a list of email addresses
> - **Anyone who signs up** — public-style app, anyone can create an account
>
> If you pick "just me" or "a few people", we'll lock the app down so only those email addresses can sign in. You can always add more people later.

Save the answer as `ALLOWLIST_MODE`:
- "Just me" → `ALLOWLIST_MODE=solo`. Use the user's GitHub email (from `gh api user --jq .email`) as the allowed email; if that's empty, ask them.
- "Me and a few specific people" → `ALLOWLIST_MODE=team`. Collect the email list now (their email plus the others).
- "Anyone who signs up" → `ALLOWLIST_MODE=open`.

**Question 6 — Payments**

> Will you need to collect money from users?
>
> - **No** — not right now
> - **Yes, one-time payments** (like buying a product or paying for a service)
> - **Yes, subscriptions** (like a monthly membership)
> - **Yes, both**
>
> If yes, we'll set up Stripe — it's what most apps use. For the prototype we'll use test mode so no real money moves around.

**Question 7 — Emails**

> Does your app need to send emails to users? Things like:
> - Welcome email when they sign up
> - Order confirmations
> - Reminders or notifications
>
> **Yes / No / Maybe later** — all fine answers.

**Question 7b — Connecting to other services**

> Will your app pull data from or push data to other services? Things like:
>
> - **Google** — Sheets, Drive, Gmail, Calendar
> - **Notion** — pages, databases
> - **Airtable** — bases and tables
> - **Slack** — messages, channels
> - **Some other service with an API** — just tell me which
> - **None** — this app stands alone
>
> Pick all that apply, or "none". For each one you'll later sign in with that service so the app can read or write data on your behalf. We'll set up a clean place to plug them in now so they're easy to add as you go.

Save the answers as `INTEGRATIONS` — a comma-separated list of provider slugs (e.g. `google,notion`) or `none`. For each one, also note briefly what it's for (e.g. `google: read calendar events`, `notion: write daily summaries`) — this lands in the build plan.

**Question 8 — Your web address (domain)**

> Do you have a web address (like myapp.com) for your app?
>
> - **Yes, I already own one** — great, what is it?
> - **I want to buy one** — the easiest way is to buy it directly through Vercel (where your site is hosted). It's usually $10-15/year and it connects to your app automatically — zero extra setup. You can do this on the free plan, you only pay for the domain itself.
>   - **Bonus:** If you ever want a professional email (like you@yourapp.com), Vercel makes it easy to set up Google Workspace email with one click.
> - **Not yet** — no worries, your app will have a free Vercel URL you can use in the meantime (like yourapp.vercel.app)

**Question 9 — Look and feel**

> Any preferences for how your app looks? All of these are optional — if you're not sure, we'll go with a clean, modern default.
>
> - **Colors** — do you have brand colors? (e.g., "blue and white", "dark theme")
> - **Vibe** — minimal and clean? Bold and colorful? Professional and polished?
> - **Logo** — do you have a logo file you'd like to use?
> - **Inspiration** — any website you love the look of?

---

### Phase 3: Let's get everything set up

Before presenting any setup steps, say:

> Great — I've got a clear picture of what you want to build! Now let's get the tools set up so we can actually make it happen. I'll check what you already have and only set up what's missing.

#### Step 3a: Detect what's already in place

Run these checks silently — do NOT show the output to the user:

```bash
bun --version 2>&1
```
```bash
gh auth status 2>&1
```
```bash
bunx vercel whoami 2>&1
```
```bash
bunx supabase --version 2>&1
```
```bash
bunx supabase projects list 2>&1
```
```bash
git remote get-url origin 2>&1
```
```bash
ls .env.local 2>/dev/null && echo "exists" || echo "missing"
```
```bash
ls vercel.json .vercel/ 2>/dev/null && echo "exists" || echo "missing"
```
```bash
cat package.json 2>/dev/null | grep next || echo "no-next"
```

Based on the results, determine which steps below to skip. If everything is already in place, say:

> Looks like you're already set up! GitHub, Vercel, Supabase, and Bun are all connected. Let's move on to your build plan.

Skip to Phase 4.

#### Step 3b: Account signup and CLI setup

Present only the steps that are needed. Wait for confirmation after each one before moving on.

**Bun** (if `bun --version` fails)

> First, let's install Bun — it's the engine that runs your app on your computer. I'll install it for you now.

Run:
```bash
curl -fsSL https://bun.sh/install | bash
```

Verify:
```bash
bun --version
```

If it fails, tell the user to restart their terminal and try again.

**GitHub** (if `gh auth status` fails)

> Next up: GitHub. This is where your app's code is stored — think of it like Google Drive, but for code. It also automatically updates your live website whenever changes are made.
>
> 1. Go to [github.com/signup](https://github.com/signup) and create a free account
> 2. Let me know when you're done and I'll connect it from here

After they confirm, run:
```bash
gh auth login --web
```

Walk them through the browser flow that opens.

**Vercel** (if `bunx vercel whoami` fails)

> Now let's set up Vercel — this is what puts your app on the internet so anyone can visit it. It's free for personal projects.
>
> 1. Go to [vercel.com](https://vercel.com) and click "Sign Up"
> 2. Choose **"Continue with GitHub"** (use the account you just created)
> 3. Let me know when you're done

After they confirm, run:
```bash
bunx vercel login
```

Walk them through the login flow.

**Supabase** (if `bunx supabase projects list` fails)

> Last account: Supabase. This is your app's database — it stores everything (users, products, orders, etc.) and handles the sign-in system.
>
> 1. Go to [supabase.com](https://supabase.com) and click "Start your project"
> 2. Choose **"Continue with GitHub"**
> 3. Don't create a project yet — we'll do that together in a moment
> 4. Let me know when you're done

After they confirm, run:
```bash
bunx supabase login
```

Walk them through the login flow.

**Stripe** (if payments were requested in Question 6)

> Next: Stripe. This is what handles payments — credit cards, subscriptions, all of it. We'll use test mode so no real money moves around during development.
>
> 1. Go to [dashboard.stripe.com/register](https://dashboard.stripe.com/register) and create a free account
> 2. Once you're in the dashboard, click **"Developers"** in the top-right, then **"API keys"**
> 3. Copy both the **Publishable key** (starts with `pk_test_`) and **Secret key** (starts with `sk_test_`)
> 4. Paste them here and I'll add them to your project

Wait for the user to provide the keys. Save them for Step 5 (.env.local).

**Resend** (if emails were requested in Question 7)

> Last service: Resend. This lets your app send emails (welcome emails, confirmations, etc.).
>
> 1. Go to [resend.com](https://resend.com) and click "Get Started"
> 2. Sign up with your GitHub account
> 3. Once you're in, go to **"API Keys"** in the sidebar and create a new key
> 4. Copy the key and paste it here

Wait for the user to provide the key. Save it for Step 5 (.env.local).

**Domain** (only if they chose to buy one in Question 8)

If they want to buy through Vercel (recommended):

> Now let's get your domain. Since you're already on Vercel, buying it there is the easiest option — it'll connect to your app automatically.
>
> 1. Go to [vercel.com/domains](https://vercel.com/domains) and search for the domain you want
> 2. Buy it — you just need a payment method on file (usually $10-15/year for a .com)
> 3. That's it! Vercel wires everything up for you
>
> This works on the free plan — you only pay for the domain itself, not the hosting.
>
> **Bonus:** Whenever you're ready for a professional email address (like you@yourdomain.com), Vercel has a one-click setup for Google Workspace. We can do that later.
>
> Let me know when you've got it!

If they already have a domain from elsewhere:

> No problem — we'll connect your existing domain later. For now, don't change any settings on your domain. We'll update the DNS to point to Vercel once your app is live.

#### Step 3c: Project scaffolding and environment wiring (default stack)

Say to the user:

> All accounts are ready! Now I'm going to set up your project — this will take a minute. I'll handle everything, just sit tight.

**Step 1: Scaffold Next.js project** (if no `package.json` with `next` detected)

Check if the current directory is empty (excluding hidden files and docs):
```bash
ls -A | grep -v '^\.' | grep -v '^docs$' | head -5
```

If the directory has existing files, ask the user before proceeding. If empty or only has docs:

```bash
bunx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-bun
```

**Step 2: Install core dependencies and UI framework**
```bash
bun add @supabase/supabase-js @supabase/ssr
bun add -d supabase
bunx shadcn@latest init --defaults
```

If payments were requested in Question 6:
```bash
bun add stripe @stripe/stripe-js
```

If emails were requested in Question 7:
```bash
bun add resend
```

**Step 3: Initialize Supabase locally**
```bash
bunx supabase init
```

**Step 3.1: Add allowlist migration** (only if `ALLOWLIST_MODE` is `solo` or `team`)

Copy the allowlist template into the project's migrations folder, replacing the placeholder owner email with the real list:

```bash
TS=$(date -u +%Y%m%d%H%M%S)
mkdir -p supabase/migrations
cp ~/.claude/plugins/marketplaces/hypt-builder/plugin/templates/allowlist.sql \
   "supabase/migrations/${TS}_allowlist.sql"
```

Then edit the new migration file: replace the `'OWNER_EMAIL@example.com'` row with one `insert ... values ('<email>', '<note>')` line per allowlisted email collected in Q5b.

Tell the user briefly:

> Locking the app down to your email(s) — only those addresses will be able to sign in. We can add more anytime by editing the `allowed_emails` table in Supabase.

**Step 3.2: Add integrations scaffolding** (only if `INTEGRATIONS` is not `none`)

Before scaffolding, normalize each provider name to a kebab-case slug (lowercase, alphanumeric and hyphens only, no spaces). Reject anything that doesn't match `^[a-z0-9-]+$` and ask the user to rename it.

Copy the integrations migration. If Step 3.1 already ran in the same second, bump the timestamp by one to avoid a Supabase migration filename collision:

```bash
TS=$(date -u +%Y%m%d%H%M%S)
# Avoid collision with the allowlist migration when both scaffolds run back-to-back.
while ls supabase/migrations/${TS}_*.sql 2>/dev/null | grep -q .; do
  TS=$(date -u -d "+1 second" +%Y%m%d%H%M%S 2>/dev/null || gdate -u -d "+1 second" +%Y%m%d%H%M%S 2>/dev/null || TS=$((TS + 1)))
done
mkdir -p supabase/migrations
cp ~/.claude/plugins/marketplaces/hypt-builder/plugin/templates/integrations.sql \
   "supabase/migrations/${TS}_integrations.sql"
```

Create the integration code skeleton — one folder per provider plus the OAuth callback and cron sync routes:

```bash
mkdir -p src/lib/integrations
mkdir -p src/app/api/integrations
mkdir -p src/app/api/cron
```

For each provider in `INTEGRATIONS`, write a stub at `src/lib/integrations/<provider>.ts` containing:

```ts
// <Provider> integration stub.
// Wire up OAuth + API calls here. Tokens are stored in the `integrations` table
// (see supabase/migrations/*_integrations.sql) and read server-side only.
export const PROVIDER = "<provider>";
```

Write a single shared OAuth callback route at `src/app/api/integrations/[provider]/callback/route.ts`:

```ts
import { NextRequest, NextResponse } from "next/server";

// Next.js 15: `params` is a Promise and must be awaited.
export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ provider: string }> },
) {
  const { provider } = await params;
  // TODO: validate `provider` against an allowlist of supported providers,
  // verify the OAuth `state` parameter to prevent CSRF, exchange `code`
  // for tokens, then upsert into the `integrations` table for the current user.
  return NextResponse.json({ provider, status: "not_implemented" }, { status: 501 });
}
```

Write a Vercel Cron entry point at `src/app/api/cron/sync/route.ts`. Vercel cron routes are publicly reachable, so the stub gates access on a shared secret:

```ts
import { NextRequest, NextResponse } from "next/server";

export async function GET(req: NextRequest) {
  // Vercel cron passes `Authorization: Bearer ${CRON_SECRET}`.
  // Reject anything else so the route isn't a public sync trigger.
  const auth = req.headers.get("authorization");
  if (!process.env.CRON_SECRET || auth !== `Bearer ${process.env.CRON_SECRET}`) {
    return new NextResponse("unauthorized", { status: 401 });
  }
  // TODO: iterate over rows in `integrations` and run per-provider sync logic.
  return NextResponse.json({ ok: true, ran_at: new Date().toISOString() });
}
```

Step 5 will write `CRON_SECRET` to `.env.local` and Step 8 will push it to Vercel. The route above reads that env var to authorize cron requests.

Add the cron schedule to `vercel.json` (create the file if missing):

```json
{
  "crons": [
    { "path": "/api/cron/sync", "schedule": "0 * * * *" }
  ]
}
```

Tell the user briefly:

> Set up a place for each integration to plug in (`src/lib/integrations/`) plus a scheduled sync that runs hourly. The actual hookup happens later when we build features that use these services.

**Step 4: Create Supabase project (remote)**

Get the user's org ID:
```bash
bunx supabase orgs list
```

Generate and save the database password (the user will need this if they ever connect directly):
```bash
DB_PASSWORD=$(openssl rand -base64 32)
echo "$DB_PASSWORD" > .supabase-db-password
chmod 600 .supabase-db-password
```

Ensure the password file is gitignored:
```bash
grep -q '.supabase-db-password' .gitignore 2>/dev/null || echo '.supabase-db-password' >> .gitignore
```

Create the project using the app name from Phase 1:
```bash
bunx supabase projects create "<app-name>" --org-id <org_id> --db-password "$DB_PASSWORD" --region us-east-1
```

Wait for the project to be ready (poll status if needed), then link it:
```bash
bunx supabase link --project-ref <project_ref>
```

If project creation fails, provide manual instructions:
> If that didn't work, no worries — let's do it manually:
> 1. Go to supabase.com/dashboard and click "New Project"
> 2. Give it a name and pick a password (save it somewhere safe)
> 3. Wait for it to finish setting up, then give me the "Project URL" and "anon key" from Settings → API

**Step 5: Create `.env.local`**

Fetch the actual credentials:
```bash
bunx supabase projects api-keys --project-ref <project_ref>
```

Write `.env.local` with the real Supabase credentials:

```
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://<project_ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon_key>
SUPABASE_SERVICE_ROLE_KEY=<service_role_key>
```

If payments were requested, add the keys collected in Step 3b:
```
# Stripe (test mode)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=<pk_test_key from user>
STRIPE_SECRET_KEY=<sk_test_key from user>
STRIPE_WEBHOOK_SECRET=
```

If emails were requested, add the key collected in Step 3b:
```
# Resend
RESEND_API_KEY=<key from user>
```

If integrations were requested in Q7b, add placeholder env vars for each provider that uses OAuth, plus the cron secret used by `/api/cron/sync`:

```
# Vercel Cron — protects /api/cron/sync from public triggers
CRON_SECRET=<openssl rand -hex 32>

# Google integration
GOOGLE_OAUTH_CLIENT_ID=
GOOGLE_OAUTH_CLIENT_SECRET=
```

Use `<PROVIDER>_OAUTH_CLIENT_ID` and `<PROVIDER>_OAUTH_CLIENT_SECRET` per provider. Generate `CRON_SECRET` now with `openssl rand -hex 32` and use the same value in Step 8 when pushing to Vercel. Leave the OAuth placeholders blank — the user fills them in when they're ready to wire up that integration. Never prefix any of these with `NEXT_PUBLIC_`.

Also create `.env.example` with the same keys but no values, for documentation.

**Step 6: Ensure `.env.local` is gitignored**
```bash
grep -q '.env*.local' .gitignore || echo '.env*.local' >> .gitignore
```

**Step 7: Link Vercel project**
```bash
bunx vercel link
```

This connects the local project to Vercel for automatic deployments.

**Step 8: Push environment variables to Vercel**
```bash
echo "<supabase_url>" | bunx vercel env add NEXT_PUBLIC_SUPABASE_URL production preview development
echo "<anon_key>" | bunx vercel env add NEXT_PUBLIC_SUPABASE_ANON_KEY production preview development
echo "<service_role_key>" | bunx vercel env add SUPABASE_SERVICE_ROLE_KEY production preview development
```

If payments were requested, also push Stripe keys:
```bash
echo "<pk_test_key>" | bunx vercel env add NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY production preview development
echo "<sk_test_key>" | bunx vercel env add STRIPE_SECRET_KEY production preview development
```

If emails were requested, also push Resend key:
```bash
echo "<resend_key>" | bunx vercel env add RESEND_API_KEY production preview development
```

If integrations were requested, push `CRON_SECRET` (and any provider OAuth credentials the user already has):
```bash
echo "<cron_secret>" | bunx vercel env add CRON_SECRET production preview development
```

**Step 9: Initialize git repo and push** (if no git remote detected)
```bash
git init
git add -A
git commit -m "chore: initial project setup — Next.js + Supabase + Vercel"
gh repo create <app-name> --private --source=. --push
```

If a git remote already exists, just commit and push the new files:
```bash
git add -A && git commit -m "chore: add Supabase and environment configuration" && git push
```

**Step 10: Verify everything works**

Start the dev server and verify it loads:
```bash
bun run dev &
DEV_PID=$!
curl -sL --retry 10 --retry-delay 2 --retry-connrefused -o /dev/null -w "%{http_code}" http://localhost:3000
kill $DEV_PID 2>/dev/null
```

If the health check returns 200, tell the user:

> Everything is connected and working! Your project is set up and ready to go.
>
> One more thing — hypt keeps itself up to date automatically, so you'll always have the latest features without lifting a finger. If you ever want to turn off auto-updates, just let me know.

If it fails, debug the issue before proceeding.

---

### Phase 4: Write the build plan

Now synthesize everything from Phases 1-2 into two documents.

#### Step 4a: Summarize and confirm

Present a summary to the user:

> Here's what I've put together based on our conversation:
>
> **[App Name]** — [one-sentence description]
>
> **Who uses it:** [user types]
>
> **What they can do:**
> - [feature 1]
> - [feature 2]
> - [feature 3]
> - ...
>
> **Sign-in:** [auth approach]
> **Payments:** [yes/no + type]
> **Emails:** [yes/no]
> **Domain:** [domain or "Vercel URL for now"]
> **Look:** [design preferences or "clean, modern default"]
>
> **Tech stack:** Next.js 15, Bun, Supabase, Vercel, Tailwind CSS + shadcn/ui
>
> Does this look right? Anything you'd add or change before I write up the plan?

Wait for confirmation. Make any requested changes.

#### Step 4b: Write the app description

Create `docs/` directory if needed:
```bash
mkdir -p docs
```

Check for existing files with the same name:
```bash
ls docs/*<idea>* 2>/dev/null
```

If a file exists for the same idea, append `-v2` (or `-v3`, etc.) to the filename.

Write `docs/YYYY-MM-DD-<idea>.md` where:
- `YYYY-MM-DD` is today's date
- `<idea>` is a short kebab-case name for the app (e.g., `dog-walker`, `meal-planner`)

Use this structure:

```markdown
# [App Name]

## What is it?

[Elevator pitch — 2-3 sentences explaining what the app does and who it's for.]

## Who uses it?

[User types, roles, and how they interact with the app.]

## What makes it different?

[Differentiator, or "This is a straightforward [category] app focused on doing the basics really well." if none provided.]

## Core features

1. **[Feature name]** — [plain description]
2. **[Feature name]** — [plain description]
3. **[Feature name]** — [plain description]
(up to 5)

## User accounts

[How people sign in — Google, email/password, both, or no accounts needed.]

## Payments

[Whether money is involved, one-time or subscription, using Stripe.]

## Notifications

[Email needs — what triggers them, or "none for now."]

## Look and feel

- **Style:** [minimal / bold / professional / custom]
- **Colors:** [brand colors or "clean modern default"]
- **Logo:** [file path or "none yet"]
- **Inspiration:** [referenced sites or "none specified"]

## Domain

[Custom domain, or "Using Vercel URL (appname.vercel.app) for now."]

## Technical stack

- **Framework:** Next.js 15 (App Router)
- **Runtime:** Bun
- **Database:** Supabase (PostgreSQL)
- **Auth:** Supabase Auth
- **Hosting:** Vercel
- **Payments:** [Stripe / not needed]
- **Email:** [Resend / not needed]
- **Styling:** Tailwind CSS + shadcn/ui
```

#### Step 4c: Write the prototype plan

Write `docs/YYYY-MM-DD-<idea>-plan.md` using the same date and idea slug.

Use this structure:

```markdown
# [App Name] — Prototype Plan

> App description: [relative link to the app description doc, e.g., `./YYYY-MM-DD-<idea>.md`]

## Overview

[1-2 sentence summary of what will be built in this prototype.]

## Users

- **Type:** [customers / internal team / marketplace / personal]
- **Authentication:** [none / Google / email+password / both]
- **Access mode:** [solo (allowlist: just owner) / team (allowlist: <N> emails) / open (anyone can sign up)]
- **Roles:** [list distinct user roles, e.g., "buyer" and "seller", or "all users are the same"]

## Pages

| Page | What it does | Sign-in required? |
|------|-------------|-------------------|
| Landing page | [description] | No |
| Sign in | [if applicable] | No |
| Dashboard | [description] | Yes |
| [Page name] | [description] | [Yes/No] |

## Features

### 1. [Feature name]
[What the user can do. What data is involved. What happens when they complete the action.]

### 2. [Feature name]
[...]

### 3. [Feature name]
[...]

(up to 5 features)

## Data Model

| Table | Purpose | Key fields |
|-------|---------|------------|
| users | User accounts (managed by Supabase Auth) | id, email, name, role, avatar_url, created_at |
| [table] | [purpose] | [fields] |

Include relationships between tables where relevant.

## Integrations

- **Auth:** Supabase Auth [with Google provider / with email+password / both]
- **Payments:** [Stripe (one-time / subscription / both) — test mode for prototype / not needed]
- **Email:** [Resend — triggered by: [list triggers] / not needed]
- **External services:** [list each provider from Q7b with its purpose, e.g. "Google Calendar — read upcoming events", "Notion — write daily summaries". Or "none" if Q7b was skipped.]
- **Sync schedule:** [if integrations exist: hourly Vercel cron at `/api/cron/sync` / n/a]

## Design

- **Style:** [from user preferences]
- **Colors:** [from user preferences, or "Tailwind default palette — neutral with a primary accent"]
- **Components:** shadcn/ui
- **Inspiration:** [from user preferences, or "clean and modern"]
- **Logo:** [file path, or "text logo using app name"]

## Technical Stack

- **Framework:** Next.js 15 (App Router)
- **Runtime & package manager:** Bun
- **Database:** Supabase (PostgreSQL) with Row Level Security
- **Auth:** Supabase Auth
- **Hosting:** Vercel
- **Payments:** [Stripe / n/a]
- **Email:** [Resend / n/a]
- **Styling:** Tailwind CSS v4 + shadcn/ui
- **Language:** TypeScript (strict mode)

## Domain

- **Domain:** [domain.com / "yourapp.vercel.app (free Vercel URL)"]
- **Registrar:** [Vercel Domains / existing registrar / n/a]
- **DNS:** [Managed by Vercel / to be configured later]

## Scope Boundaries

This is a **working prototype** — functional and live on the internet, but not production-hardened.

**Included:**
- All features listed above, working end-to-end
- User authentication and protected routes
- Responsive design (works on mobile and desktop)
- Basic error handling

**Not included yet:**
- Advanced analytics or admin dashboards
- Performance optimization for high traffic
- Automated backups or monitoring
- Comprehensive test coverage

**Good enough for:** Showing to early users, getting feedback, validating the idea, demoing to investors
**Not yet ready for:** Thousands of simultaneous users, handling real payments (Stripe test mode only)
```

#### Step 4c.5: How production-ready does this need to be?

After writing the prototype plan, ask:

> One more question — how production-ready do you need this to be?
>
> - **Prototype is fine** — get it working, polish later (default)
> - **Production-grade** — I'm relying on this; add the safety nets up front
>
> Production-grade adds error monitoring, structured logging, backup verification, an RLS audit, rate limiting on sensitive routes, secret rotation reminders, and uptime monitoring to the build plan. It's more work but the app will be sturdier from day one.

If "Production-grade", append this section to the plan file (just before `## Scope Boundaries`):

```markdown
## Production hardening

This app is intended to run reliably in production. The following are tracked as build items, not optional polish:

- [ ] **Error monitoring** — wire up Sentry (or equivalent) for both server and browser; surface unhandled errors with user context
- [ ] **Structured logging** — JSON logs with request id, user id, route, latency; ship to a queryable destination (Vercel log drains, Axiom, or Better Stack)
- [ ] **Backup verification** — confirm Supabase daily backups are on; document the restore procedure in `docs/runbooks/restore.md`
- [ ] **RLS audit** — every table has RLS enabled and at least one policy; service-role-only tables explicitly deny by default; integration tokens never exposed to the browser
- [ ] **Rate limiting** — protect auth endpoints, OAuth callbacks, cron routes, and any user-triggered external API calls (Upstash Ratelimit or Vercel Rate Limiting)
- [ ] **Secret rotation** — `.env.local` and Vercel env vars match; document how to rotate Supabase service-role key, OAuth client secrets, and any third-party API keys
- [ ] **Uptime monitoring** — external check on the production URL (Better Stack, Cronitor, or UptimeRobot); alert to email or SMS

Each item is a small task. `/prototype` will work through them after the core features are built.
```

If "Prototype is fine" (or no answer): leave the plan as-is and continue to commit.

#### Step 4d: Commit and present

```bash
git add docs/ && git commit -m "docs: add app description and prototype plan" && git push
```

Build the closing message dynamically based on which optional skills are available.

**Always include** the project status block:

> Your project is set up and your plan is ready! Here's what was created:
>
> - **App description:** `docs/YYYY-MM-DD-<idea>.md` — the big picture of your app
> - **Build plan:** `docs/YYYY-MM-DD-<idea>-plan.md` — the step-by-step plan for what to build

If `MATT_GRILL=true`, add a "Before you build" callout:

> Want me to **stress-test the plan** before you build? Say **/grill-me** and I'll walk every decision branch with you, one question at a time.

Then the workflow block. If `GSTACK` is `true`:

> Here's your development workflow:
>
> 1. **`/prototype`** — Build your app from the plan
> 2. After the build, I'll automatically test it in a real browser and check the design
> 3. **`/fix`** — Fix any bugs that come up
> 4. **`/close`** — Merge and deploy to production

If `GSTACK` is `false`:

> When you're ready to start building, just say **`/prototype`** and point it to your plan file. It'll handle the rest — implementing the features, reviewing the code, running tests, and getting it live.

Then the "Anytime" line (always shown):

> Anytime: `/save` (save work) · `/status` (is my site up?) · `/suggestions` (what's next?)

Then a single **Extras** line. Build it from whichever of these are true, joining with ` · `:

- Always: `/todo` (capture an idea)
- If `GSTACK=true`: `/cso` (security audit), `/office-hours` (rethink product), `/design-review` (visual polish)
- If `MATT_GRILL=true`: `/grill-me` (stress-test plan)

Format as: `> Extras: \`$hypt-todo\` (capture an idea) · \`/cso\` (security audit) · ...`

If neither `GSTACK` nor any `MATT_*` flag is true, omit the Extras line entirely.

Close with:

> You can also review or tweak either document before building — they're just text files.

---

### Phase 5: Set up CI (automatic testing)

After the project is scaffolded, verified, and the build plan is written, invoke the CI setup skill:

- Use `$hypt-ci-setup`

This will ask the user if they want automatic testing, and if yes, sets up GitHub Actions to run lint + unit tests on every push.

---

### Phase 6: Offer the cheatsheet

After CI setup is complete (or skipped), offer the user a quick-reference guide:

> One last thing — I made a **cheatsheet** with the commands you'll use most often. It's a one-page reference you can save or print so you always have it handy.
>
> **Would you like to see the cheatsheet?** (yes / no)

If yes: read `CHEATSHEET.md` from the project root and display its contents to the user.

If no: tell the user they can always find it by asking *"show me the cheatsheet"* or reading `CHEATSHEET.md` in their project.
