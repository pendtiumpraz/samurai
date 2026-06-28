#!/bin/bash
# modelslab-video.sh — Generate video pake ModelsLab Seedance 2.0 Mini T2V
#
# Cara panggil:
#   bash scripts/modelslab-video.sh --prompt "konsep video" [--duration 10] [--ratio 16:9] [--resolution 720p]
#
# Output: /root/.openclaw/workspace/generate/YYYYMMDD-HHMMSS-video.mp4

source /etc/environment 2>/dev/null || true

# ─── Defaults ──────────────────────────────────────────────
PROMPT=""
DURATION=5
RATIO="16:9"
RESOLUTION="720p"
OUTPUT_DIR="/root/.openclaw/workspace/generate"
MODEL="seedance-2-mini-t2v"

while [ $# -gt 0 ]; do
  case "$1" in
    --prompt|-p)    PROMPT="$2"; shift 2 ;;
    --duration|-d)  DURATION="$2"; shift 2 ;;
    --ratio|-r)     RATIO="$2"; shift 2 ;;
    --resolution|-q) RESOLUTION="$2"; shift 2 ;;
    --output|-o)    OUTPUT_DIR="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

[ -z "$PROMPT" ] && { echo "Error: --prompt required"; exit 1; }
[ "$DURATION" -lt 4 ] && DURATION=4
[ "$DURATION" -gt 15 ] && DURATION=15

mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="${OUTPUT_DIR}/${TIMESTAMP}-seedance.mp4"

echo "🎬 Generating Seedance 2.0 Mini video..."
echo "   Prompt:    ${PROMPT:0:100}..."
echo "   Duration:  ${DURATION}s"
echo "   Ratio:     $RATIO"
echo "   Resolution: $RESOLUTION"
echo ""

# ─── Submit ────────────────────────────────────────────────
RESULT=$(curl -s --max-time 120 -X POST "https://modelslab.com/api/v7/video-fusion/text-to-video" \
  -H "Content-Type: application/json" \
  -d "{
    \"key\": \"${MODELSLAB_API_KEY}\",
    \"model_id\": \"$MODEL\",
    \"prompt\": $(echo "$PROMPT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))"),
    \"aspect_ratio\": \"$RATIO\",
    \"resolution\": \"$RESOLUTION\",
    \"duration\": $DURATION
  }" 2>/dev/null)

STATUS=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','error'))" 2>/dev/null)

if [ "$STATUS" = "success" ]; then
  URL=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('output',d.get('links',['']))[0])" 2>/dev/null)
  TIME=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('generationTime','?'))" 2>/dev/null)
  
  curl -s -o "$OUTPUT_FILE" "$URL" 2>/dev/null
  
  echo "✅ Video generated in ${TIME}s!"
  echo "   File: $OUTPUT_FILE"
  echo "   URL: $URL"
elif [ "$STATUS" = "processing" ]; then
  JOB_ID=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null)
  echo "⏳ Processing (job ID: $JOB_ID)... polling..."
  
  for i in $(seq 1 30); do
    sleep 5
    FETCH=$(curl -s --max-time 30 -X POST "https://modelslab.com/api/v6/video/fetch/${JOB_ID}" \
      -H "Content-Type: application/json" \
      -d "{\"key\": \"${MODELSLAB_API_KEY}\"}" 2>/dev/null)
    FSTATUS=$(echo "$FETCH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','error'))" 2>/dev/null)
    
    if [ "$FSTATUS" = "success" ]; then
      URL=$(echo "$FETCH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('output',d.get('links',['']))[0])" 2>/dev/null)
      curl -s -o "$OUTPUT_FILE" "$URL" 2>/dev/null
      echo "✅ Video ready! → $OUTPUT_FILE"
      echo "   URL: $URL"
      exit 0
    elif [ "$FSTATUS" = "failed" ]; then
      echo "❌ Generation failed"
      echo "$FETCH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message',''))" 2>/dev/null
      exit 1
    fi
    echo -n "."
  done
  echo "⚠️  Timeout after ~150s. Check job ID: $JOB_ID"
else
  MSG=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message','unknown error'))" 2>/dev/null)
  echo "❌ Failed: $MSG"
  exit 1
fi
