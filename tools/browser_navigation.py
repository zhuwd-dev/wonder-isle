"""Read test-only coordinates and steer through ordinary keyboard input."""

import json
import re
import time


class Navigator:
    def __init__(self, page, index_html):
        self.page = page
        self.state = None
        match = re.search(r"const GODOT_CONFIG = (\{[^;]+\});", index_html)
        if not match:
            raise AssertionError("Cannot enable read-only browser telemetry: export args missing")
        config = json.loads(match.group(1))
        args = config.setdefault("args", [])
        if "--" not in args:
            args.append("--")
        args.append("--test-telemetry")
        test_html = index_html[:match.start(1)] + json.dumps(config, separators=(",", ":")) + index_html[match.end(1):]
        page.route("**/index.html?test_telemetry=1", lambda route: route.fulfill(status=200, content_type="text/html", body=test_html))
        page.on("console", self._console)

    def _console(self, message):
        if message.text.startswith("TEST_POSITION "):
            self.state = json.loads(message.text[len("TEST_POSITION "):])

    def position(self):
        deadline = time.monotonic() + 15
        while self.state is None and time.monotonic() < deadline:
            self.page.wait_for_timeout(50)
        if self.state is None:
            raise AssertionError("Game did not emit read-only test coordinates")
        return dict(self.state)

    def axis(self, axis, target, tolerance=8):
        self.page.mouse.click(800, 600)
        deadline = time.monotonic() + 20
        while time.monotonic() < deadline:
            state = self.position()
            current = state[axis]
            distance = target - current
            if abs(distance) <= tolerance:
                return
            positive = distance > 0
            key = ("d" if positive else "a") if axis == "x" else ("s" if positive else "w")
            self.page.keyboard.down(key)
            previous = current
            last_progress = time.monotonic()
            try:
                while time.monotonic() < deadline:
                    self.page.wait_for_timeout(25)
                    state = self.position()
                    current = state[axis]
                    if abs(current - previous) >= 1:
                        previous = current
                        last_progress = time.monotonic()
                    if abs(target - current) <= 20 or ((current > target) == positive):
                        break
                    if time.monotonic() - last_progress > 2:
                        raise AssertionError(f"Blocked while walking to {axis}={target}: {state}")
            finally:
                self.page.keyboard.up(key)
            self.page.wait_for_timeout(100)
        raise AssertionError(f"Timed out walking to {axis}={target}: {self.position()}")

    def go(self, *waypoints):
        for axis, target in waypoints:
            self.axis(axis, target)
