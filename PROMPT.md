# What to tell Claude

Prereq: this repo (`pagecms-starter`) and the target template repo are both open in the
same workspace, side by side.

## First run on a new template

Paste this, with `<template-repo-name>` filled in:

> I have `pagecms-starter` and `<template-repo-name>` open in this workspace. Apply the
> Pages CMS starter to `<template-repo-name>`:
> 1. Run through `pagecms-starter/CHECKLIST.md` against `<template-repo-name>` — find and
>    remove dead/duplicate content data, find hardcoded copy in its section components/layouts
>    that should be dynamic, and check prop-to-schema parity.
> 2. Copy `pagecms-starter/.pages.yml` into `<template-repo-name>/.pages.yml`.
> 3. Fill in the `components:` list and the `sections` block list in that file from
>    `<template-repo-name>`'s actual `src/components/sections/*.astro` files and their real
>    prop shapes — don't guess, read each component.
> 4. Update the `site-settings` fields to match `<template-repo-name>`'s actual `site.json`.
> 5. Tell me what you changed and what's still manual (e.g. installing the Pages CMS GitHub
>    App, which I'll do myself).
>
> Give me a plan first before executing.

## Re-run after `CHECKLIST.md` already passed once

> Apply `pagecms-starter/.pages.yml` to `<template-repo-name>` and fill in `components:` /
> `sections` from its actual section components. Skip the checklist, I already ran it.

## Feeding a new pattern back into the starter

If a template introduces a section/field shape the starter doesn't cover yet (per
`README.md` step 6):

> `<template-repo-name>` has a `<ComponentName>` section with a prop shape the
> `pagecms-starter/.pages.yml` doesn't cover. Look at it, add a matching block to
> `pagecms-starter/.pages.yml`'s `components:` list so future templates get it for free,
> then apply it to `<template-repo-name>` too.

## Notes for whichever prompt you use
- Don't ask Claude to push `pagecms-starter` changes or install the GitHub App — those are
  yours to trigger explicitly.
- If `<template-repo-name>`'s content shape differs meaningfully from
  plumbing-template-1's (different Astro content-collection structure, different settings
  file), say so up front — the starter assumes that shape.
