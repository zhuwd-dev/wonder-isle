# Mobile web layout and PWA

The Web export keeps the 1280×720 artwork proportions and expands the root Control to Godot's adaptive canvas. On wider landscape viewports, the camera scales to cover the width and crops a small amount from the top and bottom; it never stretches the world. The HTML entry uses the available browser viewport and listens for window, orientation, fullscreen, and `visualViewport` resize events.

The Web export preset enables Godot's PWA assets. `tools/prepare_web_export.py` writes the project-relative manifest and updates the generated service worker to cache content-hashed game payloads. The manifest `start_url` and service-worker scope are relative, so they stay under GitHub Pages' `/wonder-isle/` path. Navigation fetches prefer the network and fall back to the cached entry, preventing an old HTML file from pinning old game payloads. Hashed payloads remain cache-first.

On Android Chrome, tap **开始游戏** to request fullscreen from a user gesture. The game still starts if fullscreen is unavailable. Chrome can offer **添加到主屏幕** when it considers the site installable. On iPhone/iPad, Safari may refuse page fullscreen; use Safari's Share menu and **添加到主屏幕** for the standalone app. WeChat and other embedded browsers control their own chrome, so the game cannot hide those toolbars; the install guide asks players to open the page in a full browser, and on iOS specifically in Safari.

The manifest requests landscape orientation for installed browsers that honor it. Ordinary browser tabs and iOS home-screen apps may ignore orientation locking; portrait mode therefore shows a rotate-device prompt. The launch and rotate cards use CSS safe-area insets. Godot content remains inside the browser's normal safe viewport rather than forcing the page beneath device cutouts.

Run the simulated viewport/PWA checks with:

```bash
CHROMIUM_PATH=/usr/bin/chromium \
WEB_TEST_ARTIFACTS=/tmp/wonder-isle-mobile-test \
python3 tools/test_mobile_web.py /path/to/web-export
```

The browser test mounts the export at `/wonder-isle/`, checks desktop and wide canvas bounds, mobile launch/fullscreen fallback, portrait rotation, the PWA manifest, Android install-prompt handling, and service-worker scope. It does not replace real Android, iOS Safari, or WeChat device testing.
