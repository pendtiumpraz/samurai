#!/bin/bash
# gen-videos.sh — generate Seedance videos for sections 2..10 in waves.
# ponytail: unique out-dir per job avoids timestamp collisions; moves single result out.
cd /tmp/samurai-repo
VID="bash springlake/scripts/modelslab-video.sh"
BASE="lakeside Summarecon Bekasi, modern luxury high-rise apartment towers, large serene lake, lush tropical greenery, warm cinematic color grade, photorealistic"

declare -A P
P[02]="Drone flying down and forward toward a lakefront clubhouse with wooden pier and waterfront promenade, fast descend approaching the water, inviting and grand, $BASE"
P[03]="Camera spinning 360 degrees through a glassy water reflection and emerging on the opposite side of the lake with a gentle splash, magical transformative portal effect, mirror-calm water, $BASE"
P[04]="Low-angle tracking shot following a happy family walking along the lake promenade in the morning, children playing, joggers passing, warm lifestyle mood, $BASE"
P[05]="Slow smooth pan from inside a modern luxury apartment through floor-to-ceiling windows out to the lake view, natural light flooding in, premium aspirational, $BASE"
P[06]="Extreme fast zoom out from an apartment window, accelerating backward to reveal the entire lakeside cluster from high above, epic breathtaking reveal, $BASE"
P[07]="Slow drone flyover weaving through trees over green parks, botanical gardens and a tree-lined jogging track, fresh and serene, $BASE"
P[08]="Dynamic drone swoop over resort-style sports facilities, olympic swimming pool, tennis court and fitness area with active people, energetic vibrant, $BASE"
P[09]="Slow drifting time-lapse from golden hour to twilight to night, apartment tower lights and illuminated clubhouse reflecting on the calm lake, romantic magical, $BASE"
P[10]="Grand wide establishing shot slowly pulling back over the entire Springlake development at golden hour, lake glowing, aspirational closing shot, $BASE"

run() {
  local n=$1
  local dir="/root/.openclaw/workspace/generate/vid_s$n"
  rm -rf "$dir"; mkdir -p "$dir"
  $VID --prompt "${P[$n]}" --duration 10 --ratio 16:9 --resolution 480p --output "$dir" >/dev/null 2>&1
  local f=$(ls "$dir"/*.mp4 2>/dev/null | head -1)
  [ -n "$f" ] && cp "$f" "springlake/video$n.mp4" && echo "✅ video $n" || echo "❌ video $n FAILED"
}

# waves of 3
for wave in "02 03 04" "05 06 07" "08 09 10"; do
  for n in $wave; do run "$n" & done
  wait
done
echo "VIDEOS DONE"
