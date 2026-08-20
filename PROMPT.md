# What to tell Claude

Prereq: this repo (`pagecms-starter`) and the target template repo are both open in the
same workspace, side by side. Paste any of these as-is — no editing needed, Claude finds
the target repo itself (the other workspace folder that isn't `pagecms-starter` and looks
like an Astro dealer template — has `astro.config.mjs` and `src/content.config.ts`; if more
than one match, it should ask which one before doing anything).

## One-line, fully automatic

Just this — Claude reads this file and runs the whole "first run" flow below without
pausing for plan approval, then reports what it did:

> Read `pagecms-starter/PROMPT.md` and fully execute the "First run on a new template"
> prompt against the dealer-template repo in this workspace — don't stop for plan approval,
> just do it and report back when done.

## First run on a new template

> Find the dealer-template repo in this workspace (not `pagecms-starter` itself — the other
> folder with `astro.config.mjs` and `src/content.config.ts`; ask me if there's more than
> one match). Apply the Pages CMS starter to it, fully:
> 1. Run through `pagecms-starter/CHECKLIST.md` against it — find and remove dead/duplicate
>    content data, find hardcoded copy in its section components/layouts that should be
>    dynamic, and check prop-to-schema parity.
> 2. List every component in its `src/components/sections/*.astro` (or equivalent) and read
>    each one's actual prop shape — don't guess.
> 3. For every one of those components, add or update a matching block in
>    `pagecms-starter/.pages.yml`'s `components:` list so the starter covers all of them, not
>    just the worked example already there. This also updates the shared starter, so the
>    next template benefits.
> 4. Copy the now-complete `pagecms-starter/.pages.yml` into the target repo's root as
>    `.pages.yml`, with every one of its components wired into the `sections` block list.
> 5. Update the `site-settings` fields to match its actual `site.json`.
> 6. Tell me what you changed in both repos and what's still manual (e.g. installing the
>    Pages CMS GitHub App, which I'll do myself).
>
> Give me a plan first before executing.

## Re-run after `CHECKLIST.md` already passed once

Same as "First run" minus the checklist step — still reads every section component and adds
any block the starter is missing, so it's safe to use even when the target has components
the starter hasn't seen before:

> Apply `pagecms-starter/.pages.yml` to the dealer-template repo in this workspace: for every
> component in its `src/components/sections/*.astro`, add or update a matching block in
> `pagecms-starter/.pages.yml`'s `components:` list, then apply the complete config to that
> repo's `.pages.yml`. Skip the checklist, I already ran it.

## Notes for whichever prompt you use
- Don't ask Claude to push `pagecms-starter` changes or install the GitHub App — those are
  yours to trigger explicitly.
- If the target repo's content shape differs meaningfully from plumbing-template-1's
  (different Astro content-collection structure, different settings file), it should say so
  up front — the starter assumes that shape.
