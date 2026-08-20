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
> one match). Apply the Pages CMS starter to it:
> 1. Run through `pagecms-starter/CHECKLIST.md` against it — find and remove dead/duplicate
>    content data, find hardcoded copy in its section components/layouts that should be
>    dynamic, and check prop-to-schema parity.
> 2. Copy `pagecms-starter/.pages.yml` into its repo root as `.pages.yml`.
> 3. Fill in the `components:` list and the `sections` block list in that file from its
>    actual `src/components/sections/*.astro` files and their real prop shapes — don't
>    guess, read each component.
> 4. Update the `site-settings` fields to match its actual `site.json`.
> 5. Tell me what you changed and what's still manual (e.g. installing the Pages CMS GitHub
>    App, which I'll do myself).
>
> Give me a plan first before executing.

## Re-run after `CHECKLIST.md` already passed once

> Apply `pagecms-starter/.pages.yml` to the dealer-template repo in this workspace and fill
> in `components:` / `sections` from its actual section components. Skip the checklist, I
> already ran it.

## Feeding a new pattern back into the starter

If a template introduces a section/field shape the starter doesn't cover yet (per
`README.md` step 6):

> The dealer-template repo in this workspace has a section component with a prop shape
> `pagecms-starter/.pages.yml` doesn't cover. Find it, add a matching block to
> `pagecms-starter/.pages.yml`'s `components:` list so future templates get it for free,
> then apply it to that repo too.

## Notes for whichever prompt you use
- Don't ask Claude to push `pagecms-starter` changes or install the GitHub App — those are
  yours to trigger explicitly.
- If the target repo's content shape differs meaningfully from plumbing-template-1's
  (different Astro content-collection structure, different settings file), it should say so
  up front — the starter assumes that shape.
