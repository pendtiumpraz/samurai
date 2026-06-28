# Springlake Summarecon — Progress

## Completion Check
- [x] STEP 0 — Read prompt-paper.txt
- [x] STEP 1 — Web research (selling points, location)
- [x] STEP 2 — 10 storyboard images (gpt-image-2-t2i) → `storyboard/`
- [x] STEP 3 — 10 Seedance videos (seedance-2-mini-t2v, 10s/480p/16:9) → `video01..10.mp4`
- [x] STEP 4 — Extract frames @10fps → `frames/sectionNN_%04d.jpg` (100/section)
- [x] STEP 5 — Build `index.html` (10 scroll-controlled sections)
- [x] STEP 6 — `skill.md`
- [x] STEP 7 — `progress.md`
- [x] STEP 8 — git add / commit / push

## Storyboard (10 sections)
| # | Scene | Section id | Overlay |
|---|-------|-----------|---------|
| 1 | Hero — sunrise over lake | `#hero` | SPRINGLAKE / Discover Lakeside Living |
| 2 | Descent — to waterfront clubhouse | `#descent` | Welcome to Your Sanctuary |
| 3 | Portal — through water reflection | `#portal` | Where Nature Meets Luxury |
| 4 | Promenade — family lakeside | `#promenade` | Every Day Feels Like a Getaway |
| 5 | Interior — apartment with lake view | `#interior` | Your Home with a View |
| 6 | Aerial — masterplan reveal | `#aerial` | A Masterpiece of Urban Planning |
| 7 | Nature — parks & gardens | `#nature` | Embraced by Nature |
| 8 | Sports — pool, tennis, gym | `#sports` | Live Active. Live Well. |
| 9 | Night — twilight on the lake | `#night` | Where Evenings Come Alive |
| 10 | Finale — golden hour CTA | `#finale` | Your Lakeside Dream Awaits |

## Research notes (Summarecon Bekasi — real project)
- "Lake Front Vertical Living" — 8-hectare mixed-use lakefront, apartments + arcades.
- In front of Summarecon Mall Bekasi; skybridge/underpass access (no vehicle needed).
- Adjacent BINUS University & Summarecon CBD.
- Direct Jakarta–Cikampek toll; ~25 min to Jakarta via CommuterLine.
- 7,100 m² inner court; Olympic-size + thematic pools; jogging/reflexology paths, BBQ, alfresco dining.
- Units offer 4 view orientations (lake / pool / courtyard / city) + extended balconies.
- Sources: summareconbekasi.id/clusters/springlake, rumah123, brighton.co.id

## Tech
- Palette: gold #d4a853, teal #0d9488, navy #0a0a1a, cream #f5f0e8. Fonts: Playfair Display + Inter.
- Scroll technique: `.scroll-section` (300vh) → sticky `.scroll-tracker` (100vh) → frame `<img>` swapped by scroll progress. Matches existing root `index.html` pattern.
- Frames: `fps=10`, `-q:v 6` (prompt-paper said `60` but ffmpeg q:v range is 2–31).
- Overlay text reveals via IntersectionObserver; nav dots track active section.

## Notes / deviations
- `--output` flag on the scripts sets the output **directory** (filename stays timestamp-based), so each parallel job uses a unique out-dir to avoid collisions — see `scripts/gen-images.sh` / `gen-videos.sh`.
- Generation run in waves (images ×4, videos ×3) to avoid rate limits.
