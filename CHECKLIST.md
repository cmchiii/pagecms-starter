# Refactor checklist — run before wiring Pages CMS into a template

Goal: every field a dealer would want to edit is in the CMS, every field in the CMS
actually renders somewhere, editing it actually changes the live site, and there's no
duplicate/dead data left over.

## 0. The CMS is pointed at what the site actually reads
This is the single most important check — everything else is moot if it fails, and it
fails silently (no error, the page just never updates).
- [ ] For the `pages` collection, confirm `.pages.yml`'s `content[].path` is the exact
      directory the Astro content collection loader reads — check `src/content.config.ts`'s
      `glob({ base: ... })` (or equivalent) yourself, don't assume it matches `src/content/pages`.
      **Found in plumbing-template-1: `.pages.yml` pointed `pages` at `src/data/pages`, a fully
      diverged duplicate tree with stale data, while `content.config.ts` actually loaded from
      `src/content/pages`. Every CMS edit was invisible on the live site — no error, it just
      silently edited the wrong files.** This is easy to reintroduce on a new template: whichever
      directory looks like "the content one" isn't necessarily the one the loader reads.
- [ ] Do the same for every `type: file` singleton (`site.json`, `navbar.json`, etc.) — confirm the
      `path:` is the file the consuming component(s) actually import, not a same-named file that
      looks right.
- [ ] After confirming paths, make one throwaway edit through the CMS UI (or hand-edit the JSON it
      points at) and load the live page to see it change, before trusting anything else here.

## 1. Dead / duplicate data
- [ ] Grep for every content JSON directory (`src/content/**`, `src/data/**`) and confirm each
      is actually imported somewhere (`grep -rl "<dir>" src --include=*.astro --include=*.ts`).
- [ ] Delete anything with zero references — but check §0 first: a directory the CMS is
      actively (if wrongly) pointed at is not "zero references," it's the bug in §0.

## 2. Hardcoded content that should be dynamic
- [ ] Grep `src/components/sections/*.astro` and `src/layouts/**` for literal copy — strings not
      sourced from `Astro.props` or `siteConfig` (footer text, badges, nav labels, disclaimers).
- [ ] For anything a dealer would plausibly want to change per-site: promote it to a prop
      (section-specific) or into `site.json` (site-wide). Leave nothing half-wired — no prop
      that's defined but ignored, no copy that's still hardcoded next to CMS-editable siblings.
      Cheap way to do this without a visual regression: give the new prop a default equal to the
      current hardcoded string, so nothing changes until someone edits it via the CMS.

## 3. Global singletons (navbar, footer, popup/modal, announcement bar, etc.)
Templates commonly ship a JSON file *and* a schema entry for these and still hardcode the
component — the JSON just never gets read. Treat each one as its own audit, not an extension of §2:
- [ ] For each global JSON file, find its consuming component and confirm it actually imports and
      renders that data (not a parallel hardcoded config file/literal array sitting next to it —
      e.g. a `navigation.ts` with the same data duplicated and *that's* what's actually imported).
- [ ] If the consuming component is a client-hydrated island (React/Vue/Svelte with a `client:*`
      directive), it must **not** import an fs-based config loader directly — see §4, this is the
      same bug wearing a different hat. Load the config in the server-rendered parent (layout) and
      pass it down as props instead.

## 4. Config loaders: native `import`, not `fs.readFileSync`
A JSON config loader pattern like:
```ts
import fs from "node:fs"
const data = JSON.parse(fs.readFileSync(path.resolve(__dirname, "../data/x.json"), "utf-8"))
```
looks reasonable and works in dev, but breaks two ways that only surface in `npm run build`:
- If anything importing it is a client-hydrated component, Vite externalizes `node:fs`/`node:path`
  for the browser bundle and the build fails (or worse, silently ships a broken chunk).
- Even server-only, `__dirname`-relative paths resolve against the *compiled* SSR output location
  at build time, not the source tree — `path.resolve(__dirname, "../data/x.json")` ends up looking
  for `dist/data/x.json`, which doesn't exist, and the static build fails.
Use a plain `import data from "../data/x.json"` instead — Vite inlines it for both SSR and client
bundles correctly, and you get Vite's native JSON-import HMR for free (editing the file triggers a
reload without any custom Vite plugin). If a template already has a custom "watch this JSON and
force-reload" Vite plugin to work around `fs.readFileSync` not being tracked, that plugin is a
signal the loader should be switched to a native `import` and the plugin deleted.

## 5. Component props <-> CMS schema parity
- [ ] For every file in `src/components/sections/`, list its actual prop shape.
- [ ] For every prop shape, confirm a matching block exists in `.pages.yml`'s `components:`.
- [ ] For every block in `.pages.yml`, confirm the component still exists and takes those props
      (components get renamed/removed — the CMS config can silently drift out of date).
- [ ] No orphans either direction: no CMS field with nothing rendering it, no rendered prop with
      no CMS field.
- [ ] Watch for a field name reused across multiple components with a different shape in each
      (e.g. one component's `features` is `string[]`, another's is `{icon, text}`, another's is
      `{icon, title, description}`). This starter's `block`/`blockKey` pattern gives each
      component its own field set, so this can't collide *in the schema* — but if the target
      template's actual `.pages.yml` still uses one shared `props` object across all component
      types (a flatter, older pattern), reused field names **must** have one identical shape
      everywhere they appear, or CMS-authored data will silently mismatch what some components
      expect. Prefer converging on the richest shape and updating every consumer, over adding a
      same-named field with a different shape per component.

## 6. Site settings
- [ ] Diff `.pages.yml`'s `site-settings` fields against the template's actual `site.json` keys.
      Add any missing, remove any that no longer exist in that file. Don't stop at the fields a
      component obviously uses — grep the component/layout code for `siteConfig.<group>.<field>`
      to find ones only referenced conditionally (e.g. CSS custom properties built from a
      `colors.highlight` field with no schema entry, only caught because the CSS var appears
      dozens of times but the schema field doesn't exist).

## 7. Content organization — the client can actually find a page
A dealer template's `pages` collection routinely holds 80+ files nested several folders
deep (`commercial/backflow-prevention/device-installation.json`). If the CMS just lists
them flat, a client can't find anything — this is a UX bug, not a schema bug, so it's
easy to skip past.
- [ ] Confirm the `pages` collection has `subfolders: true` set. Without it, Pages CMS may not
      discover files nested inside subdirectories at all — not just fail to group them nicely.
- [ ] Confirm `view.layout: tree` (plus `view.node.filename`/`hideDirs` if the template uses
      per-folder `index.json` landing pages) so the sidebar mirrors the actual folder structure
      instead of one long flat list.
- [ ] Confirm `view.primary: meta.title` (or equivalent) so list rows show a human-readable
      title instead of the raw filename — a non-technical client can't tell `santa-monica.json`
      from `glendale.json` at a glance, but "Santa Monica Plumbing Services" they can.
- [ ] **There is no supported way to show a filtered/curated subset of a collection** (e.g. "just
      the location pages," "just this quarter's promos") — Pages CMS's `view:` schema only
      supports `layout`, `node`, `fields`, `primary`, `sort`, `search`, `default`; there is no
      `filter` key. A previous version of this starter shipped a `location-pages` collection with
      a `view.filter` block — it never worked. Because `view:` is strictly validated, the invalid
      `filter` key silently invalidated the *entire* `view:` block for that collection, which is
      why it fell back to an unstyled flat list of every file with raw filenames as labels — the
      exact "why does this look broken" symptom this section exists to prevent, caused by this
      starter itself. If a template genuinely needs a curated subset view, the only real option is
      physically nesting those files under their own subfolder so the tree groups them — which
      means their URLs change too if routing is path-based (see the next bullet).
- [ ] Before moving any page into a new subfolder for grouping, check whether the site's routing
      is path-based (the file's path *is* the URL, e.g. Astro's `getCollection` + `page.id` as the
      slug) or uses an independent `slug` field. Path-based routing means a folder move changes
      the live URL — confirm with whoever owns SEO/backlinks before doing it, and update every
      hardcoded link to the old URL (nav config, inline body links) to match.
      **Worked example (plumbing-template-1):** 16 flat root pages were cluttering the sidebar.
      7 low-SEO-risk ones (about/careers/contact/reviews/financing/specials-and-offers/
      maintenance-plan) were grouped into `company/` and `promotions/` folders, matching the
      convention the template already used for `commercial/`, `maintenance/`, `residential/`,
      `specialty/` (a landing `.json` sibling to a same-named folder). 3 SEO-sensitive city
      location pages were deliberately left flat since the client had already declined moving
      those once. Every internal href to a moved page (`navbar.json`, `footer.json`, in-page CTA
      links across ~90 content files, and hardcoded component-default `buttonHref` fallbacks like
      `buttonHref = "/contact"` in section components) had to be updated to the new path — grep
      for the old href as a quoted string across `src/content/**` and `src/components/**`, don't
      assume only the nav files reference it. A same-named `redirects:` entry was added to
      `astro.config.mjs` for every moved URL (works in static output via a meta-refresh page) so
      any old bookmark/backlink/search-index entry still resolves instead of 404ing.

## 8. Don't trust unverified keys already in a `.pages.yml` — including this starter's
A key can sit in a working-looking config for a long time without anyone noticing it does
nothing, because Pages CMS degrades a single invalid block instead of crashing the whole app —
so "the CMS didn't show an error" is not evidence a key is real (see §7's `filter` example, which
originated in this starter and was propagated across two templates before anyone checked it
against the actual source).
- [ ] Before relying on any config key that isn't obviously standard (used in an official example,
      or already proven via a successful edit-and-see-it-render round trip per §0), verify it
      against Pages CMS's real schema: `lib/config-schema.ts` in `hunvreus/pagescms` on GitHub (the
      Zod schema is authoritative and mostly `.strict()`, so anything not listed there is silently
      dropped, not applied) and/or the matching page under https://pagescms.org/docs/configuration/.
      Don't infer a key is valid because it "looks like" one from another CMS (Netlify CMS, Sanity,
      etc.) or because it appears elsewhere in the same file — `icon:` on a collection/file/field
      was never valid either and shipped throughout the original config for the same reason.
- [ ] When copying a pattern from an existing `.pages.yml` (this starter included) into a new
      template, don't assume it works just because it's already there — re-verify it the same way,
      especially anything that isn't obviously exercised by a passing build (a `props: object`
      field gets exercised the moment a component reads it; a `view:` display quirk does not).

## 9. Sanity pass
- [ ] `.pages.yml` passes Pages CMS's own validation (open the repo in the Pages CMS app, or run
      their schema validator if available) before considering the template done.
- [ ] Run a full **production build** (`npm run build`), not just the dev server. The §4 bug class
      (fs-based loaders, client-bundle breakage, `__dirname` path resolution) passes silently in
      `astro dev` and only fails at build time — dev-only testing will miss it every time.
- [ ] Spot-check the built output (`dist/`) for a few of the fields just wired up — grep the
      generated HTML for a distinctive string from each, to confirm the data actually made it
      through the whole pipeline, not just that the build didn't error.
