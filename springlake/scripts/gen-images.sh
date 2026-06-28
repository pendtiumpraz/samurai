#!/bin/bash
# gen-images.sh — generate storyboard images for sections 2..10 in waves.
# ponytail: unique out-dir per job avoids timestamp collisions; moves single result out.
cd /tmp/samurai-repo
GEN="bash springlake/scripts/modelslab-generate.sh"
BASE="lakeside Summarecon Bekasi Indonesia, modern luxury high-rise apartment towers, large serene lake, lush tropical greenery, warm cinematic color grade, photorealistic, premium real estate film still, ultra detailed"

declare -A P
P[02]="Cinematic aerial drone descending toward a lakefront clubhouse, wooden pier and waterfront promenade, $BASE"
P[03]="Surreal magical view through a glassy water reflection of luxury lakeside apartment towers, mirror-calm lake, dreamy portal-like symmetry, $BASE"
P[04]="A happy young family walking along a lake promenade at morning, children playing, joggers, palm trees, $BASE"
P[05]="Interior of a modern luxury apartment with floor-to-ceiling windows overlooking the lake, natural light flooding in, minimalist elegant furniture, $BASE"
P[06]="Epic high aerial wide shot revealing an entire master-planned lakeside apartment cluster from above, mall and boulevard nearby, $BASE"
P[07]="Lush green park with botanical gardens, tree-lined jogging track, fresh serene morning, $BASE"
P[08]="Resort-style sports facilities, olympic swimming pool, tennis court, fitness area, active vibrant people, $BASE"
P[09]="Twilight blue hour over the lake, warm glowing lights from apartment towers and illuminated clubhouse reflecting on water, romantic, $BASE"
P[10]="Grand golden-hour wide establishing shot of the entire Springlake development, lake glowing, skyline silhouette, aspirational, $BASE"

run() {
  local n=$1
  local dir="/root/.openclaw/workspace/generate/img_s$n"
  rm -rf "$dir"; mkdir -p "$dir"
  $GEN --prompt "${P[$n]}" --ratio 16:9 --output "$dir" >/dev/null 2>&1
  local f=$(ls "$dir"/*.png 2>/dev/null | head -1)
  [ -n "$f" ] && cp "$f" "springlake/storyboard/section$n.png" && echo "✅ image $n" || echo "❌ image $n FAILED"
}

# waves of 4
for wave in "02 03 04 05" "06 07 08 09" "10"; do
  for n in $wave; do run "$n" & done
  wait
done
echo "IMAGES DONE"
