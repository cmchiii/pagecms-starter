# Refactor checklist — run before wiring Pages CMS into a template

Goal: every field a dealer would want to edit is in the CMS, every field in the CMS
actually renders somewhere, and there's no duplicate/dead data left over.

## 1. Dead / duplicate data
- [ ] Grep for every content JSON directory (`src/content/**`, `src/data/**`) and confirm each
      is actually imported somewhere (`grep -rl "<dir>" src --include=*.astro --include=*.ts`).
- [ ] Delete anything with zero references. (Found in plumbing-template-1: `src/data/pages/**`
      was an orphaned pre-localization mirror of `src/content/pages/**` — not imported anywhere.)

## 2. Hardcoded content that should be dynamic
- [ ] Grep `src/components/sections/*.astro` and `src/layouts/**` for literal copy — strings not
      sourced from `Astro.props` or `siteConfig` (footer text, badges, nav labels, disclaimers).
- [ ] For anything a dealer would plausibly want to change per-site: promote it to a prop
      (section-specific) or into `site.json` (site-wide). Leave nothing half-wired — no prop
      that's defined but ignored, no copy that's still hardcoded next to CMS-editable siblings.

## 3. Component props <-> CMS schema parity
- [ ] For every file in `src/components/sections/`, list its actual prop shape.
- [ ] For every prop shape, confirm a matching block exists in `.pages.yml`'s `components:`.
- [ ] For every block in `.pages.yml`, confirm the component still exists and takes those props
      (components get renamed/removed — the CMS config can silently drift out of date).
- [ ] No orphans either direction: no CMS field with nothing rendering it, no rendered prop with
      no CMS field.

## 4. Site settings
- [ ] Diff `.pages.yml`'s `site-settings` fields against the template's actual `site.json` keys.
      Add any missing, remove any that no longer exist in that file.

## 5. Sanity pass
- [ ] `.pages.yml` passes Pages CMS's own validation (open the repo in the Pages CMS app, or run
      their schema validator if available) before considering the template done.
