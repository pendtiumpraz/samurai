# ⚔️ Samurai — Scrolling Animated Katana Website

AI-generated scrolling animation website showcasing premium Japanese katana sharpness.

## Tech

- **Video:** Seedance 2.0 Mini (ByteDance) via ModelsLab API
- **Storyboard:** GPT Image 2 T2I
- **Frames:** ffmpeg @ 10fps
- **Animation:** CSS scroll-driven frame switching
- **Stack:** Pure HTML/CSS/JS, no frameworks

## How it works

1. GPT Image 2 generated storyboard concepts
2. Storyboard used as reference for Seedance 2.0 text-to-video prompt
3. 10-second video generated ($0.44 at 480p)
4. ffmpeg extracted 100 frames
5. HTML scroll-driven animation displaying each frame on scroll

## Usage

Open `index.html` in a browser and scroll down.
