#!/bin/bash
# extract-frames.sh — videoNN.mp4 → frames/sectionNN_%04d.jpg @10fps (100 frames/10s)
cd /tmp/samurai-repo/springlake
mkdir -p frames
for n in 01 02 03 04 05 06 07 08 09 10; do
  v="video$n.mp4"
  if [ -f "$v" ]; then
    rm -f "frames/section${n}_"*.jpg
    ffmpeg -y -i "$v" -vf 'fps=10' -q:v 6 "frames/section${n}_%04d.jpg" >/dev/null 2>&1
    c=$(ls "frames/section${n}_"*.jpg 2>/dev/null | wc -l)
    echo "section$n: $c frames"
  else
    echo "section$n: ❌ NO VIDEO"
  fi
done
echo "FRAMES DONE — total: $(ls frames/*.jpg | wc -l), size: $(du -sh frames | cut -f1)"
