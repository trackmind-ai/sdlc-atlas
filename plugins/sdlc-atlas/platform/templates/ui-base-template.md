# UI Base Template — sdlc-atlas Platform
# Version: 1.0 (supersedes ui-default-template.md, ui-landing-template.md, ui-dashboard-template.md)
#
# PURPOSE:
#   THE single mandatory structural + token reference for every greenfield
#   frontend project on this platform. Every screen a project needs maps to
#   exactly one of the categories below — there is no fourth option and no
#   opt-out. Colours, fonts, and copy are OVERRIDABLE per project; structure,
#   section order, and presence of mandatory sections are FIXED and never
#   renegotiated per project "style."
#
# CATEGORIES (design-concept-agent assigns exactly one per screen, Step 3b):
#   landing   → § 1 Public / Landing Page      (Home, Marketing, Pricing, About)
#   login     → § 2 Login / Auth Screen        (Login, Sign Up, Forgot/Reset Password)
#   dashboard → § 3 Dashboard Shell            (every authenticated screen: List,
#                                                Detail, Create/Edit, Settings, Admin)
#
# HOW AGENTS USE THIS FILE:
#   1. design-concept-agent reads this to resolve tokens (§0) and to derive
#      landing/login/dashboard section content from business_brief.md +
#      ux_brief.md — NOT by asking new questions (except the one interview
#      question ux-research-agent already asked: primary user journey).
#      Writes resolved sections to ux_brief.md.
#   2. bootstrap-agent reads this to scaffold the actual screen files, routes,
#      shared Navbar/Footer components, and the Animation & Transition spec
#      (§4) as real CSS.
#   3. qa-agent's Visual dimension checks built output against the
#      Placeholder Replacement Checklist (§5) — an unresolved [PLACEHOLDER]
#      or a missing mandatory section/animation is a CRITICAL finding.
#
# COMPANION FILE:
#   ui-base-template.html — single static HTML reference implementing §0-§4
#   end to end (landing page, login screen, dashboard shell) with the
#   Animation & Transition spec as real CSS. This is a HUMAN/qa-agent visual
#   reference only — agents scaffold from this .md's structured slots and
#   must NEVER `cat` the .html into their own context.
#
# CONTEXT-BUDGET RULE (this file runs ~730 lines / ~9k tokens):
#   Agents MUST read this file section-scoped (grep/sed by `## § N` heading
#   range), never whole-file via plain `cat`. Read only §0 (tokens, always)
#   plus whichever of §1/§2/§3 the current screen/step actually needs, plus
#   §4 (animations) when scaffolding — never load all five sections unless a
#   step genuinely spans all of them (see design-concept-agent.md Step 1,
#   the one legitimate exception, and bootstrap-agent.md step 3b for the
#   per-category scoped-read pattern to copy for any new agent wiring).
#
# NON-NEGOTIABLE, top to bottom, never reordered, never skipped:
#   Landing:   Navbar → Hero → Features → Final CTA → Footer
#              (Social Proof / How It Works / Testimonials / Pricing conditional)
#   Login:     Navbar (minimal) → Auth Card → Footer
#   Dashboard: Top Nav → Sidebar → Page Header → Stat Cards → Data Table → Bottom Row
#   Every page (all 3 categories) shares the SAME Navbar/Footer component and
#   the SAME resolved token set (§0) — never a second palette, never a second
#   navbar implementation forked per screen type.

---

## § 0 — Design Tokens  [FIXED structure / OVERRIDABLE values]

### Component Library

library:        shadcn/ui          # [FIXED]
styling:        Tailwind CSS        # [FIXED]
icon_library:   lucide-react        # [FIXED]

### Colour Tokens  [OVERRIDABLE — primary + mode]

#### Light mode (default)
primary:              #3B82F6      # blue-500 — replaced by user's brand colour
primary-foreground:   #FFFFFF      # derived: white if primary is dark, dark text if primary is light
primary-hover:        #2563EB      # derived: primary darkened ~10%
primary-light:        #EFF6FF      # derived: primary at ~8% opacity
primary-muted:        #BFDBFE      # derived: primary at ~25% opacity
secondary:            #6B7280      # gray-500
secondary-foreground: #FFFFFF
accent:               #F3F4F6      # gray-100
accent-foreground:    #111827
background:           #FFFFFF
surface:              #F9FAFB      # gray-50 (cards, panels)
surface-raised:       #FFFFFF      # elevated cards
border:               #E5E7EB      # gray-200
border-focus:         #3B82F6      # matches primary
muted:                #9CA3AF      # gray-400
muted-foreground:     #6B7280
text-primary:         #111827      # gray-900
text-secondary:       #6B7280      # gray-500
text-disabled:        #D1D5DB

#### Semantic colours  [FIXED]
danger:               #EF4444
danger-bg:            #FEF2F2
danger-foreground:    #FFFFFF
success:              #22C55E
success-bg:           #F0FDF4
success-foreground:   #FFFFFF
warning:              #F59E0B
warning-bg:           #FFFBEB
warning-foreground:   #FFFFFF
info:                 #3B82F6      # matches primary

#### Dark mode overrides (applied when colour_mode is dark or both)
dark-background:      #09090B
dark-surface:         #18181B
dark-surface-raised:  #27272A
dark-border:          #3F3F46
dark-text-primary:    #FAFAFA
dark-text-secondary:  #A1A1AA

### Typography  [OVERRIDABLE — font-family only]

font-family:      Inter, system-ui, sans-serif   # replaced by user font choice
font-size-base:   16px
line-height-base: 1.5

#### Scale
text-xs:    12px / line-height: 1.4
text-sm:    14px / line-height: 1.5
text-base:  16px / line-height: 1.5
text-lg:    18px / line-height: 1.6
text-xl:    20px / line-height: 1.4
text-2xl:   24px / line-height: 1.3
text-3xl:   32px / line-height: 1.2
text-4xl:   48px / line-height: 1.1

#### Weights
font-regular:   400
font-medium:    500
font-semibold:  600
font-bold:      700

### Spacing  [FIXED]

base-unit: 4px

spacing-1:   4px
spacing-2:   8px
spacing-3:   12px
spacing-4:   16px
spacing-5:   20px
spacing-6:   24px
spacing-8:   32px
spacing-10:  40px
spacing-12:  48px
spacing-16:  64px
spacing-20:  80px

### Border Radius  [FIXED]

radius-sm:   4px
radius-md:   8px     # default for cards, inputs
radius-lg:   12px    # modals, panels, feature/testimonial cards
radius-xl:   16px
radius-full: 9999px  # pills, avatars

### Shadows  [FIXED]

shadow-sm:  0 1px 2px rgba(0,0,0,0.05)
shadow-md:  0 4px 6px rgba(0,0,0,0.07), 0 2px 4px rgba(0,0,0,0.05)
shadow-lg:  0 10px 15px rgba(0,0,0,0.08), 0 4px 6px rgba(0,0,0,0.05)
shadow-xl:  0 20px 25px rgba(0,0,0,0.10), 0 10px 10px rgba(0,0,0,0.04)

### Layout  [FIXED]

nav-h (landing/login navbar):  72px
top-nav-h (dashboard):          64px
sidebar-width:        240px    # collapsible to 64px (icon-only)
sidebar-width-mini:   64px
content-max-width:    1280px
content-padding-x:    24px     # desktop
content-padding-x-sm: 16px     # mobile

#### Breakpoints
sm:   640px
md:   768px
lg:   1024px
xl:   1280px
2xl:  1536px

### Colour Mode  [OVERRIDABLE]

default: light    # replaced by user answer: light / dark / both

### Accessibility  [FIXED]

standard:           WCAG 2.1 AA
contrast-ratio-min: 4.5:1     # normal text
contrast-ratio-lg:  3:1       # large text (18px+ bold or 24px+)
keyboard-nav:       required
focus-ring:         2px solid var(--border-focus), offset 2px
skip-links:         required
aria-labels:        required on all icon-only buttons

### Core Component Defaults  [FIXED]

#### Button
height-sm:  32px    # navbar CTA
height-md:  40px    # default
height-lg:  48px    # hero CTA
padding-x:  16px
variants:   primary, secondary, outline, ghost, destructive, link

#### Input / Form fields
height:       40px  (38px for auth-card inputs)
padding-x:    12px
border-width: 1px
border-color: var(--border)
focus-color:  var(--border-focus)
focus-ring:   0 0 0 3px rgba(primary, 0.12)

#### Card
padding:      24px
border-width: 1px
border-color: var(--border)
bg:           var(--surface-raised)
radius:       var(--radius-lg)

#### Modal / Dialog
max-width-sm: 400px
max-width-md: 560px    # default
max-width-lg: 768px
overlay-bg:   rgba(0,0,0,0.5)

#### Table
row-height:      48px
header-height:   48px
header-bg:       var(--surface)
row-hover-bg:    var(--accent)
border-collapse: separate
border-spacing:  0

#### Toast / Notification
position:     bottom-right
max-width:    400px
duration-ms:  4000

---

## § 1 — Public / Landing Page  [category: `landing`]

```
┌─────────────────────────────────────────────────────────────────┐
│  NAVBAR  (sticky, 72px, transparent→solid on scroll)             │
│  [Logo] [Project Name]   [Nav Links]      [Secondary CTA] [Primary CTA] │
├───────────────────────────────────────────────────────────────────┤
│  HERO  (min-height: 85vh desktop, 100vh mobile)                   │
│    [Eyebrow badge]                                                 │
│    [H1 — value proposition, 2 lines max]                          │
│    [Subhead — 1-2 sentences, what/who/why]                        │
│    [Primary CTA button]  [Secondary CTA — ghost/link]             │
│    [Hero visual — product screenshot / illustration / mockup]     │
│    [Trust bar — logos or one-line social proof, optional]         │
│                                                                     │
│  SOCIAL PROOF  (conditional)                                      │
│  FEATURES  (3-column grid, repeats in groups of 3)                │
│  HOW IT WORKS  (conditional)                                      │
│  TESTIMONIALS  (conditional)                                      │
│  PRICING  (conditional)                                           │
│                                                                     │
│  FINAL CTA  (full-width band, contrasting background)             │
│  FOOTER  (SHARED across landing/login/dashboard)                  │
└─────────────────────────────────────────────────────────────────┘
```

Mandatory, top to bottom, never reordered: **Navbar → Hero → Features → Final
CTA → Footer.** Social Proof, How It Works, Testimonials, Pricing are
conditional (see include/omit rules below). Never add a section beyond this
list, never invent a "nicer" layout — consistency across every page this
platform builds is the point.

### Navbar (shared component — see § 3.1 for its dashboard/login variants)

height:           72px
background:       transparent over hero, `var(--background)` + `var(--shadow-sm)` once scrolled past hero
position:         sticky, top: 0, z-index: 300
border-bottom:    1px solid transparent → `var(--border)` on scroll
transition:       background-color 200ms ease, box-shadow 200ms ease   # see § 4

#### Slots
```yaml
logo:           32x32px, radius-md, background var(--primary), placeholder [PROJECT_LOGO]
brand-name:     16px / 700, placeholder [PROJECT_NAME]
nav-links:      center (desktop) / hidden behind hamburger (<768px), 14px/500, gap 32px
                items derived from Features section anchors + [ABOUT_LINK] + [PRICING_LINK if present]
mobile-menu:    hamburger 24x24px <768px only; full-screen overlay, slide-in from right 280ms ease (§ 4)
secondary-cta:  ghost/link variant, label [SECONDARY_NAV_CTA] (e.g. "Log in") — visible only if login screens exist
primary-cta:    primary button height-sm, label [PRIMARY_NAV_CTA] (e.g. "Get started")
```

### Hero

min-height:   85vh desktop, 100vh mobile (padding-top 72px accounts for navbar)
layout:       centered column (SaaS/consumer default) OR split 50/50 text+visual (product-heavy)
background:   var(--background), optional subtle gradient/pattern using var(--primary) at low opacity — never an undirected stock photo
padding:      spacing-20 y (desktop) / spacing-12 y (mobile), content-padding-x

#### Slots
```yaml
eyebrow-badge:   optional, pill style, placeholder [HERO_EYEBROW] — omit if nothing to announce
headline:        h1, text-4xl (clamp to text-3xl <480px), 700-800, line-height 1.1, max 2 lines
                 placeholder [HERO_HEADLINE] — business_brief § Value Proposition, <12 words
subhead:         p, text-lg, text-secondary, max-width 640px (centered) / no cap (split)
                 placeholder [HERO_SUBHEAD] — business_brief § Problem Statement + target user
cta-group:       flex row gap 16px, wrap on mobile
  primary:       height-lg, placeholder [HERO_PRIMARY_CTA] — MVP Scope core action
  secondary:     outline/ghost height-lg, placeholder [HERO_SECONDARY_CTA] — omit if only one clear action
hero-visual:     product screenshot (browser-chrome/device frame) | illustration | none
                 radius-lg, shadow-xl, border 1px var(--border)
                 placeholder [HERO_VISUAL_DESCRIPTION] — bootstrap-agent scaffolds placeholder box + alt text
trust-bar:       optional — "Trusted by [N]+ [user type]" or 4-6 greyscale logo placeholders
                 visible only if business_brief § Competitive Landscape/Success Metrics implies real traction
```

### Social Proof  [CONDITIONAL]

include-when:  business_brief § Success Metrics names a concrete traction number, OR § Competitive Landscape references named customers/partners
omit-when:     no such signal — a fabricated stats bar is worse than no section
layout:        3-4 column grid, centered, no card background, padding-y spacing-12

```yaml
# numeric variant
stat_1: { value: [METRIC_VALUE], label: [METRIC_LABEL] }
stat_2: { value: [METRIC_VALUE], label: [METRIC_LABEL] }
stat_3: { value: [METRIC_VALUE], label: [METRIC_LABEL] }
# OR logo variant (use instead if named customers exist)
logos: [LOGO_1] [LOGO_2] [LOGO_3] [LOGO_4] [LOGO_5]   # greyscale opacity 0.6, hover opacity 1
```

### Features

layout:        3-column grid desktop / 2-column tablet / 1-column mobile (<768px), gap 32px, padding-y spacing-20
section-header: eyebrow [FEATURES_EYEBROW], title [FEATURES_TITLE], centered, max-width 600px

```yaml
# each card: icon 48x48 (primary-light bg, radius-lg, primary icon, lucide-react),
# title 16px/600, description 14px/text-secondary 2-3 sentences max
feature_1: { icon: [ICON], title: [FEATURE_TITLE], desc: [FEATURE_DESC] }
feature_2: { icon: [ICON], title: [FEATURE_TITLE], desc: [FEATURE_DESC] }
feature_3: { icon: [ICON], title: [FEATURE_TITLE], desc: [FEATURE_DESC] }
# feature_4..9 as needed, always multiples of 3, derived from business_brief § Must-Have list
```

### How It Works  [CONDITIONAL]

include-when:  primary user flow (from ux_brief § Primary User Journey / § Customer Journey) has 3+ meaningful steps worth explaining visually
omit-when:     value is self-evident from Features alone, or the flow is a single action
layout:        horizontal step sequence desktop (connected line/arrow), vertical stack mobile
step-count:    3 (never more than 4)

```yaml
step_1: { number: "01", title: [STEP_TITLE], desc: [STEP_DESC] }  # journey phase 1
step_2: { number: "02", title: [STEP_TITLE], desc: [STEP_DESC] }  # journey phase 2
step_3: { number: "03", title: [STEP_TITLE], desc: [STEP_DESC] }  # journey phase 3 / outcome
```

### Testimonials  [CONDITIONAL]

include-when:  business_brief provides real customer quotes, OR domain has a strong trust/credibility need (healthcare, fintech, B2B enterprise)
omit-when:     no real quotes exist — NEVER fabricate a quote; if included with no content yet, scaffold `<!-- TODO: replace with real customer testimonial -->`
layout:        2-3 column grid, or single-column for exactly 1 quote
card:          surface-raised bg, border 1px var(--border), radius-lg, padding 24px, shadow-sm

```yaml
testimonial_1: { quote: [QUOTE_TEXT], name: [PERSON_NAME], role: [PERSON_ROLE_COMPANY] }  # avatar: initials fallback 40x40 circle
```

### Pricing  [CONDITIONAL]

include-when:  business_brief § Business Objectives/Success Metrics defines a monetization model
omit-when:     internal tool, no monetization, or "contact us"-only enterprise (use single CTA card instead of a tier grid)
layout:        3-column grid, center tier elevated (scale 1.02, shadow-lg, border-color primary)

```yaml
tier_1: { name: [TIER_NAME], price: [PRICE], period: [PERIOD], features: [FEATURE_LIST], cta: [TIER_CTA_LABEL] }
tier_2: { name: [TIER_NAME], price: [PRICE], period: [PERIOD], features: [FEATURE_LIST], cta: [TIER_CTA_LABEL], badge: "Most popular" }
tier_3: { name: [TIER_NAME], price: [PRICE], period: [PERIOD], features: [FEATURE_LIST], cta: [TIER_CTA_LABEL] }
```

### Final CTA

layout:      full-width band, centered content, max-width 720px
background:  var(--primary) or var(--accent) — high-contrast from the section above
padding-y:   spacing-16

```yaml
title:    [FINAL_CTA_TITLE]     # restated value prop
subtitle: [FINAL_CTA_SUBTITLE]  # optional, one line
cta:      [FINAL_CTA_LABEL]     # same action as hero primary CTA
```

### Footer (SHARED across landing / login / dashboard — one implementation, never forked)

background:   var(--surface) or var(--dark-surface) if dark default
border-top:   1px solid var(--border)
padding:      spacing-16 y, content-padding-x x

```
┌───────────────────────────────────────────────────────────┐
│  [Logo] [Project Name] · [One-line description]              │
│  [Col 1: Product]    [Col 2: Company]    [Col 3: Resources] │
│  ─────────────────────────────────────────────────────────  │
│  [Social icons]   [© YYYY Project Name]   [Privacy][Terms]   │
└───────────────────────────────────────────────────────────┘
```

```yaml
brand:    { logo: [PROJECT_LOGO], name: [PROJECT_NAME], tagline: [ONE_LINE_DESCRIPTION] }
columns:
  col_1: { heading: Product, links: [FEATURES_LINK] [PRICING_LINK if present] [ABOUT_LINK] }
  col_2: { heading: Company, links: [ABOUT_LINK] [CONTACT_LINK] [CAREERS_LINK if applicable] }
  col_3: { heading: Resources, links: [DOCS_LINK if applicable] [SUPPORT_LINK] [BLOG_LINK if applicable] }
social-icons: { library: lucide-react, visible: only platforms confirmed in business_brief.md — never invent }
legal:    { copyright: "© [CURRENT_YEAR] [PROJECT_NAME]. All rights reserved.", links: [PRIVACY_LINK] [TERMS_LINK] }
```

Dashboard pages use this same Footer component, simplified to a single copyright line if the dashboard shell is dense (see § 3).

---

## § 2 — Login / Auth Screen  [category: `login`]

Applies to Login, Sign Up, Forgot Password, Reset Password. First-class
category — not a variant of landing, not a variant of dashboard. Public
(pre-auth), so it shares the landing Navbar/Footer, but never the Hero/
Features/Social-Proof/Pricing sections.

```
┌─────────────────────────────────────────────────────────────────┐
│  NAVBAR  (minimal — logo + brand-name only, no nav-links,        │
│           no secondary CTA; single "Back to home" or nothing)    │
├───────────────────────────────────────────────────────────────────┤
│                                                                     │
│              ┌───────────────────────────────┐                    │
│              │  AUTH CARD  (max-width 400px)  │                    │
│              │    [Eyebrow/logo mark]         │                    │
│              │    [H1 — "Log in" / "Sign up"] │                    │
│              │    [Subtext — one line]        │                    │
│              │    [Form fields]               │                    │
│              │    [Primary CTA — full width]  │                    │
│              │    [Secondary link — "Forgot   │                    │
│              │       password?" / "Sign up"]  │                    │
│              │    [Divider + SSO buttons,      │                    │
│              │       only if business_brief    │                    │
│              │       specifies SSO/OAuth]      │                    │
│              └───────────────────────────────┘                    │
│                                                                     │
│  FOOTER  (shared, simplified to copyright + legal links only)     │
└─────────────────────────────────────────────────────────────────┘
```

Mandatory, never reordered: **Navbar (minimal) → Auth Card → Footer.**

### Navbar (minimal variant)

Same component as § 1 Navbar, with `nav-links`, `secondary-cta` slots
omitted — only `logo` + `brand-name`, optionally a single ghost-style
"Back to home" link. Same 72px height, same scroll-transition behaviour (§ 4).

### Auth Card

background:   var(--surface-raised)
border:       1px solid var(--border)
border-radius: radius-lg
padding:      32px
shadow:       shadow-md
max-width:    400px
position:     centered horizontally and vertically within the page's main content area (min-height: calc(100vh - navbar - footer))

#### Slots
```yaml
title:        h1, text-2xl/700, placeholder [AUTH_TITLE]     # "Log in to [PROJECT_NAME]" / "Create your account"
subtext:      text-sm, text-secondary, placeholder [AUTH_SUBTEXT]  # one line, optional
fields:       derived per screen purpose —
              Login:            email/username, password
              Sign Up:          name, email, password (+ confirm if business_brief implies it)
              Forgot Password:  email only
              Reset Password:   new password, confirm password
primary-cta:  full-width button height-lg, placeholder [AUTH_PRIMARY_CTA]  # "Log in" / "Create account" / "Send reset link"
secondary-link: text-sm centered below CTA, placeholder [AUTH_SECONDARY_LINK]
              # Login → "Don't have an account? Sign up" + "Forgot password?"
              # Sign Up → "Already have an account? Log in"
sso-block:    optional — divider "or continue with" + SSO provider buttons
              visible: only if business_brief.md explicitly names an SSO/OAuth provider — never invent one
```

Field labels/CTA copy are pulled from the screen's row in `ux_brief.md`'s
Screen Inventory (purpose / key actions columns) — never invented boilerplate
beyond the structural defaults above.

---

## § 3 — Dashboard Shell  [category: `dashboard`]

Applies to every authenticated screen: List, Detail, Create/Edit, Settings,
Admin, Dashboard/Overview, Reports.

```
┌─────────────────────────────────────────────────────────────────┐
│  TOP NAV  (fixed, 64px)                                         │
│  [Logo] [Project Name]    [Search]    [Notifications] [Avatar]  │
├──────────────┬──────────────────────────────────────────────────┤
│  SIDEBAR     │  MAIN CONTENT (max-width 1280px, padding 32px)   │
│  (240px)     │    PAGE HEADER: [Eyebrow] [Title] [Actions]      │
│              │    STAT CARDS (4-column grid)                    │
│  [Nav Items] │    DATA TABLE (toolbar + rows + pagination)      │
│              │    BOTTOM ROW: [Quick Form] [Activity Feed]      │
│  [User Row]  │                                                   │
└──────────────┴──────────────────────────────────────────────────┘
```

Mandatory: **Top Nav → Sidebar → Page Header → Stat Cards → Data Table →
Bottom Row.** A screen that is a Detail/Edit view rather than a list may
substitute Stat Cards/Data Table for the equivalent content region, but Top
Nav, Sidebar, and Page Header are never omitted.

### § 3.1 — Top Nav (dashboard variant of the shared Navbar component)

height:       64px, background var(--background), border-bottom 1px var(--border), fixed top z-index-200

```yaml
logo:           32x32px radius-md, primary bg, placeholder [PROJECT_LOGO]
brand-name:     15px/700, placeholder [PROJECT_NAME]
search:         360px max, 36px height, surface bg, border 1px var(--border), placeholder "Search…"
notifications:  icon button 36x36, red-dot badge when unread
settings:       icon button 36x36
avatar:         34x34 radius-full, primary-light bg, 2px primary-muted border, placeholder [USER_INITIALS]
```

### Sidebar

width 240px, background var(--surface), border-right 1px var(--border), fixed top:64px bottom:0, padding 16px 12px.

Nav item: height 36px, padding 8px 12px, radius-md, 14px, 16x16 lucide-react
icon, states default/hover/active, active-bg primary-light, active-color
primary, optional count badge.

```yaml
group_1:
  label: Main   # replace with project group name
  items:
    - { icon: Home, label: Dashboard, route: /dashboard }
    - { icon: [ICON], label: [ITEM_LIST], route: /[resource], badge: [COUNT] }
    - { icon: Users, label: [USERS/MEMBERS], route: /[users] }
    - { icon: BarChart2, label: [ANALYTICS], route: /[analytics] }   # omit nav item if not in MVP scope
group_2:
  label: Manage   # replace with project group name
  items:
    - { icon: FileText, label: [REPORTS], route: /[reports] }        # omit nav item if not in MVP scope
    - { icon: Settings, label: Settings, route: /settings }
```

Sidebar footer: user-avatar 30x30 radius-full, user-name 13px/600
[USER_NAME], user-role 11px muted [USER_ROLE].

### Page Header

margin-bottom 28px.

```yaml
eyebrow:  12px/500, primary colour, placeholder [SECTION_NAME]
title:    24px/700, letter-spacing -0.02em, placeholder [PAGE_TITLE]
subtitle: 14px, text-secondary, placeholder [PAGE_SUBTITLE]
actions:  top-right, flex row gap 8px — button_1 outline [SECONDARY_ACTION], button_2 primary [PRIMARY_ACTION]
```

### Stat Cards

4-column grid, gap 16px, margin-bottom 28px. Card: surface-raised bg, border
1px var(--border), radius-lg, padding 20px, shadow-sm.

```yaml
card_1: { label: "Total [ITEMS]", value: [NUMBER], delta: up|down|flat, delta_pct: [PERCENT], sub: "vs. last month" }
card_2: { label: "Active [ITEMS]", value: [NUMBER], delta: up|down|flat, delta_pct: [PERCENT], sub: "currently active" }
card_3: { label: [KEY_METRIC], value: [VALUE], delta: up|down|flat, delta_pct: [PERCENT], sub: "this period" }
card_4: { label: [REVENUE_OR_VOLUME], value: [VALUE], delta: up|down|flat, delta_pct: [PERCENT], sub: [COMPARISON_LABEL] }
```

Delta colours: up → success-bg/green, down → danger-bg/red, flat →
accent/muted.

### Data Table

surface-raised bg, border 1px var(--border), radius-lg, shadow-sm,
margin-bottom 24px.

Toolbar: padding 14px 20px, border-bottom 1px var(--border), search-input
240px max height 34px placeholder "Filter [items]…", filter-button and
columns-button outline style.

```yaml
columns:
  - { key: checkbox, width: 44px, type: checkbox }
  - { key: name, label: [NAME], type: primary+secondary }
  - { key: category, label: [CATEGORY], type: text }
  - { key: status, label: Status, type: status-pill }
  - { key: date, label: [DATE], type: mono-date }
  - { key: value, label: [VALUE], type: mono-number }
  - { key: actions, width: 72px, type: row-actions }
```

Status pill variants: active (success-bg/green), pending (warning-bg/amber),
inactive (accent/muted), error (danger-bg/red). Row height 48px, hover
surface bg. Footer: "[N] of [TOTAL] results" + pagination.

### Bottom Row (2-column grid, gap 20px)

#### Panel Left — Quick Create Form

surface-raised bg, border 1px var(--border), radius-lg, shadow-sm. Header:
title "Add [ITEM]", ghost "Clear" action.

```yaml
field_1: { label: [PRIMARY_FIELD], type: text, placeholder: "Enter [primary field]…" }
field_2: { label: [SECONDARY_FIELD], type: text, placeholder: "Enter [secondary field]…" }
field_3: { label: [CATEGORY], type: select, options: [CATEGORY_A], [CATEGORY_B], [CATEGORY_C] }
field_4: { label: [OPTIONAL_FIELD], type: text, placeholder: "Optional…" }
form-actions: { primary: "Save [ITEM]", secondary: Cancel }
```

Input spec: height 38px, padding-x 12px, border 1px var(--border), radius-md,
focus-ring 0 0 0 3px rgba(primary,0.12).

#### Panel Right — Activity Feed

Same card chrome. Header: title "Recent Activity", ghost "View all" action.
Item: flex row gap 12px, icon 30x30 circle (semantic bg by event type), text
13px "[User] did [action] on [item]", time 11px muted, 1px border separator.

```yaml
events:
  - { type: created, text: "[User] created [Item]", time: "2 minutes ago" }
  - { type: warning, text: "[Item] moved to [Status]", time: "18 minutes ago" }
  - { type: updated, text: "[User] updated [Item]", time: "1 hour ago" }
  - { type: deleted, text: "[Item] was removed", time: "3 hours ago" }
  - { type: joined, text: "New [User] [Name] joined", time: "Yesterday" }
```

Icon colour by event: created/joined → success-bg/green, updated →
primary-light/primary, warning → warning-bg/amber, deleted → danger-bg/red.

---

## § 4 — Animation & Transition Spec  [FIXED — mandatory, not optional]

Every project scaffolded from this template includes these transitions as
real CSS (see ui-base-template.html for the reference implementation).
Omitting them is a template-adherence defect, exactly like omitting a Navbar
or Footer.

```yaml
navbar-scroll:      background-color 200ms ease, box-shadow 200ms ease
                    # transparent → solid once scrolled past hero (landing/login only)
mobile-menu:        slide-in from right, 280ms ease
                    # full-screen overlay on <768px, traps focus while open
page-transition:    fade + slight upward slide-in on route change, 150-200ms ease-out
                    # applies uniformly across landing/login/dashboard route changes
hover-interactions:  background/color transition 100-150ms ease on buttons, nav items, row actions, table rows
focus-ring:         instant (no transition delay) — accessibility requirement, never animated in
card-hover:         subtle shadow elevation on interactive cards (stat cards, feature cards, table rows), 150ms ease
loading-skeleton:   pulse animation, 1.5s ease-in-out infinite, on any data-dependent region before data resolves
button-press:       scale(0.98) on :active, 100ms ease — primary/secondary buttons only
```

Reduced-motion: every transition above respects `prefers-reduced-motion:
reduce` — durations collapse to near-instant, no slide/scale transforms, per
the § 0 Accessibility standard.

---

## § 5 — Placeholder Replacement Checklist

design-concept-agent works through this list writing ux_brief.md.
bootstrap-agent works through this list scaffolding files. qa-agent's Visual
dimension treats any leftover `[PLACEHOLDER]` in built output as a CRITICAL
finding, and a missing mandatory section (including § 4 animations) as a
CRITICAL finding — regardless of how good the rest looks.

```
[ ] [PROJECT_NAME]            — from context_bundle.md
[ ] [PROJECT_LOGO]            — initials or icon derived from project name
[ ] [SECONDARY_NAV_CTA]       — "Log in" if login screens exist, else omit slot
[ ] [PRIMARY_NAV_CTA]         — from business_brief § Feature Prioritization core action
[ ] [HERO_EYEBROW]            — omit unless a real announcement exists; never fabricate
[ ] [HERO_HEADLINE]           — business_brief § Value Proposition, <12 words
[ ] [HERO_SUBHEAD]            — business_brief § Problem Statement + target user
[ ] [HERO_PRIMARY_CTA]        — business_brief § MVP Scope core action
[ ] [HERO_SECONDARY_CTA]      — omit if only one clear action
[ ] [HERO_VISUAL_DESCRIPTION] — placeholder box description until real content exists
[ ] social proof section      — included only if business_brief justifies it, else omitted
[ ] [FEATURES_EYEBROW] / [FEATURES_TITLE] — from business_brief § Value Proposition
[ ] feature_1..N              — business_brief § Must-Have list, multiples of 3
[ ] how-it-works section      — included only if a 3+ step journey benefits from explanation
[ ] testimonials section      — included only with real quotes or strong trust need; never fabricated
[ ] pricing section           — included only if business_brief defines a monetization model
[ ] [FINAL_CTA_TITLE] / [FINAL_CTA_LABEL] — restated value prop / same action as hero primary CTA
[ ] footer columns + links    — only real, confirmed destinations
[ ] [AUTH_TITLE] / [AUTH_SUBTEXT] — per screen purpose (Login/Sign Up/Forgot/Reset)
[ ] auth fields                — per screen purpose, see § 2 fields table
[ ] [AUTH_PRIMARY_CTA] / [AUTH_SECONDARY_LINK] — per screen purpose
[ ] sso-block                  — only if business_brief names a real SSO/OAuth provider
[ ] [USER_INITIALS] / [USER_NAME] / [USER_ROLE] — placeholders until auth is wired
[ ] [SECTION_NAME] / [PAGE_TITLE] / [PAGE_SUBTITLE] — from ux_brief.md Screen Inventory
[ ] [PRIMARY_ACTION] / [SECONDARY_ACTION] — from ux_brief.md Component Map
[ ] [ITEM] / [ITEM_LIST] / [USERS/MEMBERS] — entity + nav labels from domain
[ ] [ANALYTICS] / [REPORTS]    — nav labels, or remove item if not in MVP scope
[ ] [KPI_1..4 labels]           — business_brief § MVP Scope key metrics
[ ] [TABLE_COLUMNS] / [STATUS_VARIANTS] — from ux_brief.md Component Map / domain
[ ] [FORM_FIELDS] / [CATEGORY_OPTIONS] / [ACTIVITY_EVENTS] — from ux_brief.md / domain
[ ] --primary / --font-sans     — same resolved values everywhere, ONE shared token set
[ ] § 4 Animation & Transition CSS — present and wired on every scaffolded screen
```

---

## Responsiveness rules  [FIXED — applies to every section in §1-§3]

```
<768px (mobile):
  - Navbar/Top Nav: hamburger menu (landing/login) or icon-only sidebar (dashboard)
  - Hero: single column, headline text-3xl, hero-visual below text, full-width CTAs
  - Features/Pricing/Testimonials: 1 column
  - Dashboard: sidebar collapses to icon-only (64px) or off-canvas
  - Footer: columns stack vertically

768px–1023px (tablet):
  - Features: 2 columns
  - Hero split layout collapses to stacked if present
  - Dashboard: sidebar may collapse to icon-only

≥1024px (desktop):
  - Full layout as specified in each section
  - content-max-width 1280px applies to inner content; section background may be full-bleed

Touch targets ≥44x44px on any breakpoint below 1024px — accessibility floor, not a suggestion.
```

## Accessibility  [FIXED — inherits § 0, plus:]

- Each page's H1 is the ONLY h1 (Hero headline on landing, Auth title on login, Page title on dashboard) — every other heading is h2+.
- Every CTA/button has accessible text describing the action, never "Click here".
- hero-visual and illustrative images have descriptive alt text, never `alt=""` unless purely decorative with a text equivalent beside it.
- Mobile hamburger menu and any modal trap focus while open, return focus to trigger on close.
- Colour contrast for text over Final CTA / primary-background bands must meet 4.5:1 — verify explicitly.
