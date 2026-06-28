#!/bin/bash
# modelslab-generate.sh — Generate gambar pake ModelsLab GPT Image 2
#
# Cara panggil (dari Claude Code):
#   bash scripts/modelslab-generate.sh --prompt "..." --ratio 16:9
#   bash scripts/modelslab-generate.sh --prompt "..." --size 1536x1024
#
# Cara panggil dari OpenClaw:
#   bash scripts/modelslab-generate.sh --prompt "AI company poster" --size 1536x1024
#
# Output: /root/.openclaw/workspace/generate/YYYYMMDD-HHMMSS-{aspect}.png

source /etc/environment 2>/dev/null || true

# ─── Aspect Ratio → Pixel Sizes ───────────────────────────
# Constraints: divisible by 16, >= 1MP (minimum pixel budget)
# Tested & working with ModelsLab GPT Image 2 T2I
declare -A ASPECT_SIZES
ASPECT_SIZES["1:1"]="1024x1024"     # exact 1:1
ASPECT_SIZES["2:3"]="1024x1536"     # exact 2:3
ASPECT_SIZES["3:2"]="1536x1024"     # exact 3:2
ASPECT_SIZES["3:4"]="1152x1536"     # exact 3:4
ASPECT_SIZES["4:3"]="1536x1152"     # exact 4:3
ASPECT_SIZES["9:16"]="864x1536"     # exact 9:16 (1.3MP)
ASPECT_SIZES["16:9"]="1824x1024"    # ~16:9 (1.8MP)
ASPECT_SIZES["2K"]="2048x1152"      # 2K 16:9 (2.4MP)
ASPECT_SIZES["4K"]="4096x2304"      # 4K 16:9 (tesis)

# ─── Parse Arguments ──────────────────────────────────────
PROMPT=""
SIZE=""
RATIO="1:1"
OUTPUT_DIR="/root/.openclaw/workspace/generate"

while [ $# -gt 0 ]; do
  case "$1" in
    --prompt|-p)  PROMPT="$2"; shift 2 ;;
    --size|-s)    SIZE="$2"; shift 2 ;;
    --ratio|-r)   RATIO="$2"; shift 2 ;;
    --output|-o)  OUTPUT_DIR="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

# ─── Validate ──────────────────────────────────────────────
[ -z "$PROMPT" ] && { echo "Error: --prompt required"; exit 1; }

if [ -z "$SIZE" ]; then
  SIZE="${ASPECT_SIZES[$RATIO]}"
  [ -z "$SIZE" ] && { echo "Error: Unknown ratio '$RATIO'. Use: ${!ASPECT_SIZES[*]}"; exit 1; }
fi

# ─── Generate ──────────────────────────────────────────────
mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="${OUTPUT_DIR}/${TIMESTAMP}-${SIZE}.png"

echo "→ Generating: $SIZE ($RATIO)"
echo "→ Prompt: ${PROMPT:0:80}..."

RESULT=$(curl -s --max-time 300 -X POST "https://modelslab.com/api/v7/images/text-to-image" \
  -H "Content-Type: application/json" \
  -d "{
    \"key\": \"${MODELSLAB_API_KEY}\",
    \"model_id\": \"gpt-image-2-t2i\",
    \"prompt\": $(echo "$PROMPT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))"),
    \"size\": \"$SIZE\",
    \"samples\": 1,
    \"safety_checker\": \"no\"
  }" 2>/dev/null)

STATUS=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','error'))" 2>/dev/null)

if [ "$STATUS" = "success" ]; then
  URL=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('output',d.get('links',['']))[0])" 2>/dev/null)
  PROXY=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('proxy_links',[''])[0])" 2>/dev/null)
  TIME=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('generationTime','?'))" 2>/dev/null)
  
  curl -s -o "$OUTPUT_FILE" "$URL"
  echo ""
  echo "✅ Generated in ${TIME}s"
  echo "   File: $OUTPUT_FILE"
  echo "   URL: $URL"
else
  MSG=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message','unknown error'))" 2>/dev/null)
  echo "❌ Failed: $MSG"
  exit 1
fi
