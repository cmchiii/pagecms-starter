# pagecms-starter

Reusable [Pages CMS](https://pagescms.org) config for the dealer-template repos. Not a shared backend — Pages CMS reads `.pages.yml` from each repo's own root via its GitHub App, so this is a **starter you copy into every template**, kept in one place so the pattern stays consistent.

## What's here

- **`.pages.yml`** — base config matching the Astro content-collection shape (`meta` + polymorphic `sections` block list + `noindex`/`draft`, plus `site.json` settings). See its header comments for what to fill in per-template.
- **`CHECKLIST.md`** — refactor checklist to run against a template *before* wiring the CMS to it: kill dead/duplicate data, remove hardcoded copy that should be editable, keep component props and CMS schema in sync.
- **`scripts/apply.ps1`** — copies `.pages.yml` into a target template repo (does not overwrite an existing one without confirmation).

## Using it on a new template

1. Run `CHECKLIST.md` against the target repo first — the config is only correct if the repo's data is.
2. `pwsh scripts/apply.ps1 -Target ../that-template-repo`
3. Open `.pages.yml` in the target repo, add a `components:` entry for every section component the template actually has (copy the `HeroSection` block as a pattern), and uncomment the matching lines in `content[0].fields[].blocks`.
4. Adjust `site-settings` fields to match that template's actual `site.json`.
5. Commit, install the Pages CMS GitHub App on that repo, and test-edit a real page.
6. If the template introduces a genuinely new field type or pattern not covered here, fold it back into this starter so the next template benefits too.

## Why `sections` is a `block` field, not `object`

Each page's `sections` array holds different component types (`{ component: "HeroSection", props: {...} }`, `{ component: "CTAStrip", props: {...} }`, ...) — a polymorphic list. Pages CMS models that with `type: block` + `blockKey` (the property that stores which variant it is) + `blocks` (the list of allowed variants, each referencing a shared `components:` definition by name). This was verified against the CMS's own schema source (`types/field.ts`, `lib/config-schema.ts` in pages-cms/pages-cms), not assumed from the docs site, which was missing this example.
