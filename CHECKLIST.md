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
them flat, or the tree/filter views that are *supposed* to group them aren't wired
correctly, a client can't find anything — this is a UX bug, not a schema bug, so it's
easy to skip past.
- [ ] Confirm the `pages` collection has `subfolders: true` set. Without it, Pages CMS may not
      discover files nested inside subdirectories at all — not just fail to group them nicely.
- [ ] Confirm `view.layout: tree` (plus `view.node.filename`/`hideDirs` if the template uses
      per-folder `index.json` landing pages) so the sidebar mirrors the actual folder structure
      instead of one long flat list.
- [ ] For any secondary "quick find" filtered collection (this starter ships `location-pages`,
      filtering on `meta.isLocationPage == true` — adapt the flag/filter for whatever grouping a
      given template needs, e.g. seasonal promos, a specific service line): **the filter field
      must actually be true on the pages it's supposed to surface.** A schema-only filter with no
      data behind it returns zero results — no error, the group just looks empty forever.
      **Found in plumbing-template-1: `location-pages` filtered on `meta.isLocationPage`, but
      none of the three actual location pages (santa-monica/pasadena/glendale) had that key set —
      the quick-find list was silently empty.** Grep the target pages' JSON for the filter field
      before trusting a filtered collection is populated.
- [ ] If a filtered collection shares its `path` with the main collection (so it reads the same
      files rather than a duplicate empty one), `settings.content.merge: true` must be set at the
      YAML root, or Pages CMS won't merge the two collections' schemas correctly.
- [ ] Make the filter field itself CMS-editable (a `boolean` field on `meta`, in this case) —
      otherwise the only way to add a page to the group is hand-editing JSON outside the CMS,
      which defeats the point of giving the client a findable, click-to-toggle grouping.

## 8. Sanity pass
- [ ] `.pages.yml` passes Pages CMS's own validation (open the repo in the Pages CMS app, or run
      their schema validator if available) before considering the template done.
- [ ] Run a full **production build** (`npm run build`), not just the dev server. The §4 bug class
      (fs-based loaders, client-bundle breakage, `__dirname` path resolution) passes silently in
      `astro dev` and only fails at build time — dev-only testing will miss it every time.
- [ ] Spot-check the built output (`dist/`) for a few of the fields just wired up — grep the
      generated HTML for a distinctive string from each, to confirm the data actually made it
      through the whole pipeline, not just that the build didn't error.
