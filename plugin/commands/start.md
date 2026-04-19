---
description: "Onboarding for new projects — understand your idea, set up accounts, and create a build plan"
allowed-tools: ["Bash", "Read", "Write", "Grep", "Glob", "Skill"]
---

# /start — New Project Onboarding

## Preamble (run silently before the skill)

```bash
_UPD=$(~/.claude/plugins/marketplaces/hypt-builder/bin/hypt-update-check 2>/dev/null || true)
echo "${_UPD:-UP_TO_DATE}"
GSTACK_AVAILABLE=$(test -f ~/.claude/skills/gstack/SKILL.md && echo "true" || echo "false")
echo "GSTACK: $GSTACK_AVAILABLE"
```

- If output contains `UPGRADE_AVAILABLE <old> <new>`: Silently run `bash ~/.claude/plugins/marketplaces/hypt-builder/install.sh` then briefly tell the user: "hypt updated to v{new}. Restart Claude Code when convenient to use the latest version." Then continue with the skill normally.
- If output contains `JUST_UPGRADED <old> <new>`: Briefly say "Running hypt v{new} (updated from v{old})." then continue.
- Otherwise: continue silently — say nothing about updates.
- `GSTACK` line: note silently whether gstack is available. Do not mention this to the user yet (Phase 0b will handle gstack recommendation).

## Context

- Working directory: !`pwd`
- Existing docs: !`ls docs/*.md 2>/dev/null || echo "No docs yet"`
- Git status: !`git remote get-url origin 2>&1 || echo "No git repo yet"`
- Package.json: !`cat package.json 2>/dev/null | head -5 || echo "No package.json"`

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

- **Type:** [customers / internal team / marketplace]
- **Authentication:** [none / Google / email+password / both]
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

#### Step 4d: Commit and present

```bash
git add docs/ && git commit -m "docs: add app description and prototype plan" && git push
```

If `GSTACK` is `true`, tell the user:

> Your project is set up and your plan is ready! Here's what was created:
>
> - **App description:** `docs/YYYY-MM-DD-<idea>.md` — the big picture of your app
> - **Build plan:** `docs/YYYY-MM-DD-<idea>-plan.md` — the step-by-step plan for what to build
>
> Here's your development workflow:
>
> 1. **`/prototype`** — Build your app from the plan
> 2. After the build, I'll automatically test it in a real browser and check the design
> 3. **`/fix`** — Fix any bugs that come up
> 4. **`/close`** — Merge and deploy to production
>
> Anytime: `/save` (save work) · `/status` (is my site up?) · `/suggestions` (what's next?)
>
> Extras: `/cso` (security audit) · `/office-hours` (rethink product) · `/design-review` (visual polish)
>
> You can also review or tweak either document before building — they're just text files.

If `GSTACK` is `false`, tell the user:

> Your project is set up and your plan is ready! Here's what was created:
>
> - **App description:** `docs/YYYY-MM-DD-<idea>.md` — the big picture of your app
> - **Build plan:** `docs/YYYY-MM-DD-<idea>-plan.md` — the step-by-step plan for what to build
>
> When you're ready to start building, just say **`/prototype`** and point it to your plan file. It'll handle the rest — implementing the features, reviewing the code, running tests, and getting it live.
>
> You can also review or tweak either document before building — they're just text files.

---

### Phase 5: Set up CI (automatic testing)

After the project is scaffolded, verified, and the build plan is written, invoke the CI setup skill:

- Invoke the Skill tool with skill: "hypt:ci-setup"

This will ask the user if they want automatic testing, and if yes, sets up GitHub Actions to run lint + unit tests on every push.

---

### Phase 6: Offer the cheatsheet

After CI setup is complete (or skipped), offer the user a quick-reference guide:

> One last thing — I made a **cheatsheet** with the commands you'll use most often. It's a one-page reference you can save or print so you always have it handy.
>
> **Would you like to see the cheatsheet?** (yes / no)

If yes: read `CHEATSHEET.md` from the project root and display its contents to the user.

If no: tell the user they can always find it by asking *"show me the cheatsheet"* or reading `CHEATSHEET.md` in their project.
