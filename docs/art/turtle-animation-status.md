# Turtle animation status

## Current state

`assets/art/characters/turtle.png` is one transparent 504×597 illustration. It shows a friendly four-legged turtle in a planted standing pose, but contains no animation frames or separate limb layers. The project therefore keeps the turtle stationary at its pond habitat so it remains easy to find and interact with; the single pose is not translated along a patrol path.

Status: **ASSET_REQUIRED** for a credible crawl cycle.

## Required source art

- Keep the existing face, shell pattern, flowers, color palette, and body proportions.
- Supply at least four matching side-view crawl frames (front and rear feet alternate while the shell remains stable), plus a planted idle frame.
- Use a common 512×512 transparent frame canvas with a fixed ground contact point at `(256, 468)`; keep the visible turtle within the canvas and leave at least 24 px transparent margin around the silhouette.
- Provide left-facing art; right-facing may mirror the left only if the shell/face details are not directional. Up/down views must be drawn, never made by rotating the side view.
- Target 6–8 frames per second, looping for crawl and holding a single idle frame. Keep the shadow as a separate, stable ground layer.

Once matching art exists, connect it to an animation controller and validate a real crawl clip, a stop/turn clip, and Q005 handoff before restoring patrol movement.
