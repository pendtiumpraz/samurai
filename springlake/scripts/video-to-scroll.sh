#!/bin/bash
# video-to-scroll.sh — Convert video ke scrolling animated website
#
# Cara panggil:
#   bash scripts/video-to-scroll.sh <video-url|video-file> [--fps 12] [--quality 80]
#   bash scripts/video-to-scroll.sh video.mp4 --fps 8 --quality 70
#   bash scripts/video-to-scroll.sh https://...video.mp4 --fps 10
#
# Output: /root/.openclaw/workspace/generate/YYYYMMDD-HHMMSS-scroll.html

set -e

# ─── Config ────────────────────────────────────────────────
FPS=10          # Frame per second (makin tinggi makin smooth tapi berat)
QUALITY=60      # JPEG quality (1-100, makin rendah makin kecil file)
OUTPUT_DIR="/root/.openclaw/workspace/generate"
SOURCE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --fps)        FPS="$2"; shift 2 ;;
    --quality|-q) QUALITY="$2"; shift 2 ;;
    --output|-o)  OUTPUT_DIR="$2"; shift 2 ;;
    -*)
      # Skip known args that might be part of --prompt etc
      if [ "$1" = "--prompt" ] || [ "$1" = "-p" ] || [ "$1" = "--duration" ] || [ "$1" = "-d" ] || [ "$1" = "--ratio" ] || [ "$1" = "-r" ] || [ "$1" = "--resolution" ]; then
        shift 2; continue
      fi
      echo "Unknown: $1"; exit 1 ;;
    *)
      if [ -z "$SOURCE" ]; then SOURCE="$1"; shift; else echo "Extra arg: $1"; exit 1; fi ;;
  esac
done

[ -z "$SOURCE" ] && { echo "Error: butuh URL video atau file video"; exit 1; }

mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
WORKDIR="${OUTPUT_DIR}/${TIMESTAMP}-frames"
mkdir -p "$WORKDIR"

VIDEO_FILE="$WORKDIR/source.mp4"

# ─── Download video ────────────────────────────────────────
if [[ "$SOURCE" =~ ^https?:// ]]; then
  echo "📥 Downloading video..."
  curl -sL -o "$VIDEO_FILE" "$SOURCE" || { echo "❌ Download failed"; exit 1; }
else
  VIDEO_FILE="$SOURCE"
fi

# ─── Validate ──────────────────────────────────────────────
if ! command -v ffmpeg &>/dev/null; then
  echo "❌ ffmpeg gak ketemu. Install dulu: apt install ffmpeg"
  exit 1
fi

# ─── Extract frames ────────────────────────────────────────
echo "🎞️ Extracting frames at ${FPS}fps..."
mkdir -p "$WORKDIR/jpg"
ffmpeg -i "$VIDEO_FILE" -vf "fps=${FPS}" -q:v "$QUALITY" -loglevel error "$WORKDIR/jpg/frame_%04d.jpg"

TOTAL_FRAMES=$(ls "$WORKDIR/jpg"/*.jpg 2>/dev/null | wc -l)
[ "$TOTAL_FRAMES" -eq 0 ] && { echo "❌ No frames extracted"; exit 1; }
echo "   Got $TOTAL_FRAMES frames"

# ─── Generate scrolling HTML ──────────────────────────────
echo "🌐 Building scrolling website..."

# Copy frames ke base64 inline (kecil-kecil doang) atau jadi img src
# Kita pake pendekatan image path relatif ke folder frames biar HTMLnya portable
# Tapi kalo mau all-in-one bisa base64

# Ambil first frame buat detect size
FIRST_FRAME=$(ls "$WORKDIR/jpg"/*.jpg | head -1)
IMG_SIZE=$(identify "$FIRST_FRAME" 2>/dev/null | awk '{print $3}' || echo "auto")
IMG_W=$(echo "$IMG_SIZE" | cut -d'x' -f1)
IMG_H=$(echo "$IMG_SIZE" | cut -d'x' -f2)
[ -z "$IMG_W" ] && IMG_W=1024
[ -z "$IMG_H" ] && IMG_H=576

# Kalo frame kebanyakan, kita skip sampling biar ga bottleneck
DESIRED_FRAMES=120  # max frames biar html gak kegedean
SKIP=1
if [ "$TOTAL_FRAMES" -gt "$DESIRED_FRAMES" ]; then
  SKIP=$((TOTAL_FRAMES / DESIRED_FRAMES + 1))
  echo "   Sampling: skip ${SKIP} frames (${TOTAL_FRAMES} → ~$((TOTAL_FRAMES / SKIP)) frames)"
fi

# Build HTML
FRAMES_DIR="frames_${TIMESTAMP}"
mkdir -p "$OUTPUT_DIR/$FRAMES_DIR"

# Copy sampled frames to output dir
IDX=0
SAMP=0
for f in "$WORKDIR/jpg"/*.jpg; do
  IDX=$((IDX + 1))
  if [ $(( (IDX - 1) % SKIP )) -eq 0 ]; then
    SAMP=$((SAMP + 1))
    cp "$f" "$OUTPUT_DIR/$FRAMES_DIR/$(printf '%04d' $SAMP).jpg"
  fi
done
TOTAL_IN_HTML=$SAMP
echo "   Embedding ${TOTAL_IN_HTML} frames in HTML"

# ─── Generate CSS scroll-driven animation ─────────────────
cat > "$OUTPUT_DIR/${TIMESTAMP}-scroll.html" << HTMLHEADER
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Scrolling Animation</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    background: #0a0a0f;
    overflow-x: hidden;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  }

  /* ─── Scroll Container ─── */
  .scroll-container {
    position: relative;
    width: 100%;
  }

  /* ─── Sticky Frame Viewer ─── */
  .frame-viewer {
    position: sticky;
    top: 0;
    width: 100%;
    height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
    background: #0a0a0f;
  }

  .frame-viewer img {
    max-width: 100%;
    max-height: 100vh;
    object-fit: contain;
    display: block;
    image-rendering: auto;
    transition: opacity 0.1s ease;
  }

  /* ─── Frame Trigger Sections ─── */
  .frame-section {
    height: 100vh;
    width: 100%;
    pointer-events: none;
  }

  /* ─── Info Bar ─── */
  .info-bar {
    position: fixed;
    bottom: 20px;
    left: 50%;
    transform: translateX(-50%);
    background: rgba(0,0,0,0.7);
    backdrop-filter: blur(10px);
    color: #fff;
    padding: 8px 20px;
    border-radius: 20px;
    font-size: 13px;
    z-index: 100;
    border: 1px solid rgba(255,255,255,0.1);
    display: flex;
    align-items: center;
    gap: 12px;
  }
  .info-bar .frame-count { color: #8b5cf6; font-weight: 600; }
  .progress-bar {
    width: 100px;
    height: 3px;
    background: rgba(255,255,255,0.2);
    border-radius: 2px;
    overflow: hidden;
  }
  .progress-bar .fill {
    height: 100%;
    width: 0%;
    background: linear-gradient(90deg, #8b5cf6, #3b82f6);
    transition: width 0.1s;
  }

  /* ─── Mobile ─── */
  @media (max-width: 768px) {
    .info-bar { font-size: 11px; padding: 6px 14px; gap: 8px; }
    .progress-bar { width: 60px; }
  }
</style>
</head>
<body>

<div class="scroll-container">
  <div class="frame-viewer">
    <img id="scrollFrame" src="${FRAMES_DIR}/0001.jpg" alt="Animation Frame">
  </div>
HTMLHEADER

# Generate sections: each section triggers the frame
for i in $(seq 1 $TOTAL_IN_HTML); do
  printf -v PADDED '%04d' $i
  cat >> "$OUTPUT_DIR/${TIMESTAMP}-scroll.html" << FRAME_SECTION
  <div class="frame-section" data-frame="${PADDED}" style="background: transparent;"></div>
FRAME_SECTION
done

# Generate JS
cat >> "$OUTPUT_DIR/${TIMESTAMP}-scroll.html" << HTMLFOOTER
</div>

<div class="info-bar">
  <span>🎬 Frame <span class="frame-count" id="frameDisplay">1</span> / ${TOTAL_IN_HTML}</span>
  <div class="progress-bar"><div class="fill" id="progressFill"></div></div>
</div>

<script>
(function() {
  const frameImg = document.getElementById('scrollFrame');
  const frameDisplay = document.getElementById('frameDisplay');
  const progressFill = document.getElementById('progressFill');
  const sections = document.querySelectorAll('.frame-section');
  const total = sections.length;
  const viewer = document.querySelector('.frame-viewer');

  // Preload images
  const images = [];
  for (let i = 1; i <= total; i++) {
    const img = new Image();
    const padded = String(i).padStart(4, '0');
    img.src = '${FRAMES_DIR}/' + padded + '.jpg';
    images.push(img);
  }

  // Current visible frame
  let currentFrame = 1;

  function updateFrame() {
    const scrollY = window.scrollY;
    const viewH = window.innerHeight;
    const docH = document.documentElement.scrollHeight;

    // Calculate visible section based on scroll
    let frameIdx = 1;
    for (let i = 0; i < sections.length; i++) {
      const rect = sections[i].getBoundingClientRect();
      // When top of section is near viewport center-ish:
      // Using 0.85 threshold: trigger when top < 85% of viewport height
      if (rect.top < viewH * 0.85) {
        frameIdx = i + 1;
      } else {
        break;
      }
    }

    // Clamp
    if (frameIdx < 1) frameIdx = 1;
    if (frameIdx > total) frameIdx = total;

    if (frameIdx !== currentFrame) {
      currentFrame = frameIdx;
      const padded = String(frameIdx).padStart(4, '0');
      const src = '${FRAMES_DIR}/' + padded + '.jpg';

      // Pre-fetch next/prev
      const next = Math.min(frameIdx + 1, total);
      const prev = Math.max(frameIdx - 1, 1);
      if (next !== frameIdx) {
        const nImg = new Image();
        nImg.src = '${FRAMES_DIR}/' + String(next).padStart(4, '0') + '.jpg';
      }
      if (prev !== frameIdx) {
        const pImg = new Image();
        pImg.src = '${FRAMES_DIR}/' + String(prev).padStart(4, '0') + '.jpg';
      }

      frameImg.src = src;
      frameDisplay.textContent = frameIdx;
    }

    // Progress
    const pct = Math.min((scrollY / (docH - viewH)) * 100, 100);
    progressFill.style.width = pct + '%';
  }

  // Throttled scroll handler
  let ticking = false;
  window.addEventListener('scroll', function() {
    if (!ticking) {
      window.requestAnimationFrame(function() {
        updateFrame();
        ticking = false;
      });
      ticking = true;
    }
  });

  // Initial update
  window.addEventListener('load', updateFrame);
  window.addEventListener('resize', updateFrame);
  setTimeout(updateFrame, 100);
})();
</script>
</body>
</html>
HTMLFOOTER

# ─── Cleanup ────────────────────────────────────────────────
rm -rf "$WORKDIR"

HTML_FILE="${OUTPUT_DIR}/${TIMESTAMP}-scroll.html"
SIZE_KB=$(du -sk "$OUTPUT_DIR/$FRAMES_DIR" 2>/dev/null | awk '{print $1}')
SIZE_MB=$((SIZE_KB / 1024))

echo ""
echo "✅ Scrolling website selesai!"
echo "   HTML: $HTML_FILE"
echo "   Frames: $OUTPUT_DIR/$FRAMES_DIR/"
echo "   Total frames: $TOTAL_IN_HTML"
echo "   Size: ~${SIZE_MB}MB"
echo ""
echo "📌 Buka file HTML di browser buat liat hasilnya"
echo "   (frame images must be in same directory as HTML)"
