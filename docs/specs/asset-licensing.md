# Spec: Third-Party Asset Licensing

**Status:** Approved · **Last updated:** 2026-11-01

This applies to every asset we didn't make ourselves: music, sound effects, fonts, graphics.

## 1. Allowed licenses

| License | Allowed | Conditions |
|---|---|---|
| **CC0** / public domain | yes | none (still record it in the credits) |
| **CC BY** (3.0 / 4.0) | yes | name author, title, source and license in the credits; note any changes |
| **SIL OFL** (fonts only) | yes | include the license file |
| **CC BY-SA** | only after a case-by-case check | an edited version (cut, looped) must be released under BY-SA too |
| **CC BY-NC** (any NC variant) | **no** | would block a commercial release (e.g. on Steam) |
| **CC BY-ND** (any ND variant) | **no** | we have to cut, loop and crossfade tracks |
| "Free for personal use", unclear, or no license | **no** | |

## 2. Rules

- **Every third-party asset gets an entry in [`/CREDITS.md`](../../CREDITS.md) when it's added**, not afterwards. Each entry records: file path, title, author, source URL, license plus a link to it, changes made, and the date added.
- **Keep the original download** (or at least the source URL and a screenshot of the license page) so we can prove the license later.
- **In-game credits** are generated from `CREDITS.md` or kept in sync with it.
- **Suggested music sources:** Free Music Archive (filter by license), OpenGameArt, incompetech (Kevin MacLeod, CC BY).
- **Content guidelines still apply** to licensed assets.
