# Skill: Scroll-Controlled Cinematic Landing Page (AI video → frames)

Reusable workflow for building a premium, scroll-driven landing page where each
section is a short AI-generated video played frame-by-frame as the user scrolls.

## When to use
Premium product / real-estate / brand pages that should feel cinematic: the
scroll *is* the camera. Each section = one ~10s video → 100 JPG frames → scrubbed
on scroll inside a sticky viewport.

## Pipeline
1. **Research** — WebSearch the subject; pull real selling points, location, stats.
2. **Storyboard** — N sections, each: scene + camera move + mood + text overlay.
3. **Images (optional ref)** — `gpt-image-2-t2i` via `scripts/modelslab-generate.sh --prompt '...' --ratio 16:9`.
4. **Videos** — `seedance-2-mini-t2v` via `scripts/modelslab-video.sh --prompt '...' --duration 10 --ratio 16:9 --resolution 480p`. ~$0.44 / 10s@480p. Put camera movement IN the prompt.
5. **Frames** — `ffmpeg -i videoNN.mp4 -vf 'fps=10' -q:v 6 frames/sectionNN_%04d.jpg` → 100 frames/section. (`-q:v` range is 2–31; lower = better.)
6. **HTML** — see pattern below. All inline, only dep is Google Fonts.

## Gotchas (learned)
- `modelslab-*.sh --output` sets the output **DIRECTORY**, not the file — filename is
  timestamp-based. Parallel jobs in the same second collide. Fix: give every job a
  **unique out-dir**, then move the lone result out. See `scripts/gen-images.sh`.
- Run generation in **waves** (images ×4, videos ×3) — avoids rate limits, ~3× faster than serial.
- Images land in `/root/.openclaw/workspace/generate/` — copy into the repo.
- Video gen is async: the script submits then polls fetch endpoint (~2 min).

## The scroll technique (core)
```html
<section class="scroll-section">          <!-- 300vh: gives scroll room -->
  <div class="scroll-tracker">            <!-- sticky, top:0, 100vh, overflow:hidden -->
    <img class="scroll-frame" id="secNNFrame" src="frames/sectionNN_0001.jpg">
  </div>
</section>
```
```js
// progress through the section → frame index
const sec = node.closest('.scroll-section');
const top = sec.getBoundingClientRect().top + scrollY;
const progress = clamp01((scrollY - top) / (sec.offsetHeight - innerHeight));
const idx = clamp(1, total, Math.round(progress*(total-1)+1));
img.src = `frames/${prefix}${pad(idx)}.jpg`;
// preload idx-3 .. idx+6 into an Image() cache for smooth scrub
```
Wrap the scroll handler in `requestAnimationFrame` + a `ticking` flag. Reveal overlay
text and active nav dots with `IntersectionObserver`, not scroll math.

## Files
- `scripts/modelslab-generate.sh` — image (gpt-image-2-t2i)
- `scripts/modelslab-video.sh` — video (seedance-2-mini-t2v)
- `scripts/gen-images.sh` / `gen-videos.sh` — wave drivers (collision-safe)
- `index.html` — final page
