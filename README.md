# pagecms-starter

Reusable [Pages CMS](https://pagescms.org) config for the dealer-template repos. Not a shared backend — Pages CMS reads `.pages.yml` from each repo's own root via its GitHub App, so this is a **starter you copy into every template**, kept in one place so the pattern stays consistent.

## What's here

- **`.pages.yml`** — base config matching the Astro content-collection shape (`meta` + polymorphic `sections` block list + `noindex`/`draft`), plus `site.json` settings and the three common global singletons (`navbar.json`, `footer.json`, `popup-modal.json`). The `pages` collection ships with folder-tree grouping (`subfolders: true` + `view.layout: tree`) and a `location-pages` quick-find view filtered on a `meta.isLocationPage` flag, so a client can find one of dozens of nested pages without scrolling a flat list — see CHECKLIST.md §7 before assuming either is actually working for a given template. See its header comments for what to fill in per-template.
- **`CHECKLIST.md`** — refactor checklist to run against a template *before* wiring the CMS to it: confirm the CMS is actually pointed at the data the site reads (the most common and most silent failure mode), kill dead/duplicate data, remove hardcoded copy that should be editable, wire up global singletons, avoid the fs-loader build-breakage pattern, and keep component props and CMS schema in sync.
- **`scripts/apply.ps1`** — copies `.pages.yml` into a target template repo (does not overwrite an existing one without confirmation).
- **`PROMPT.md`** — copy-paste prompts for telling Claude to apply this starter to a template once both repos are open in the same workspace.

## Using it on a new template

1. Run `CHECKLIST.md` against the target repo first — the config is only correct if the repo's data is, and §0 (CMS path vs. actual content path) in particular fails silently if skipped.
2. `pwsh scripts/apply.ps1 -Target ../that-template-repo`
3. Open `.pages.yml` in the target repo, add a `components:` entry for every section component the template actually has (copy the `HeroSection` block as a pattern), and uncomment the matching lines in `content[0].fields[].blocks`.
4. Adjust `site-settings` fields to match that template's actual `site.json`. If the template doesn't have one (or more) of `navbar.json`/`footer.json`/`popup-modal.json`, delete that `content:` entry rather than leaving a schema block for a file that doesn't exist.
5. Confirm every `content[].path` actually matches what the template's components read (CHECKLIST.md §0) — do this before, not after, committing.
6. Commit, install the Pages CMS GitHub App on that repo, and test-edit a real page — confirm the edit shows up on the live site, not just that the CMS saved without error.
7. If the template introduces a genuinely new field type or pattern not covered here, fold it back into this starter so the next template benefits too.

## Why `sections` is a `block` field, not `object`

Each page's `sections` array holds different component types (`{ component: "HeroSection", props: {...} }`, `{ component: "CTAStrip", props: {...} }`, ...) — a polymorphic list. Pages CMS models that with `type: block` + `blockKey` (the property that stores which variant it is) + `blocks` (the list of allowed variants, each referencing a shared `components:` definition by name). This was verified against the CMS's own schema source (`types/field.ts`, `lib/config-schema.ts` in pages-cms/pages-cms), not assumed from the docs site, which was missing this example.
