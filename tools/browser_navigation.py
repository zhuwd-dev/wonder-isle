"""Read test-only coordinates and steer through ordinary keyboard input."""

import json
import re
import time


class Navigator:
    def __init__(self, page, index_html):
        self.page = page
        self.state = None
        self.state_received_at = 0.0
        self.competition_state = None
        self.competition_state_received_at = 0.0
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
            self.state_received_at = time.monotonic()
        elif message.text.startswith("TEST_COMPETITION "):
            self.competition_state = json.loads(message.text[len("TEST_COMPETITION "):])
            self.competition_state_received_at = time.monotonic()

    def position(self):
        deadline = time.monotonic() + 15
        while self.state is None and time.monotonic() < deadline:
            self.page.wait_for_timeout(50)
        if self.state is None:
            raise AssertionError("Game did not emit read-only test coordinates")
        if time.monotonic() - self.state_received_at > 3:
            raise AssertionError(f"Game telemetry stopped updating; cannot diagnose a collision from stale coordinates: {self.state}")
        return dict(self.state)

    def wait_for_fresh_state(self, after=0.0, timeout=15):
        """Wait for a reloaded Godot page to emit telemetry from its new instance."""
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if self.state is not None and self.state_received_at > after and time.monotonic() - self.state_received_at <= 3:
                return dict(self.state)
            self.page.wait_for_timeout(50)
        raise AssertionError(f"Godot did not emit fresh browser telemetry after reload: {self.state}")

    def competition_position(self):
        deadline = time.monotonic() + 12
        while self.competition_state is None and time.monotonic() < deadline:
            self.page.wait_for_timeout(50)
        if self.competition_state is None:
            raise AssertionError("Competition session did not emit browser telemetry")
        if time.monotonic() - self.competition_state_received_at > 3:
            raise AssertionError(f"Competition telemetry stopped updating: {self.competition_state}")
        return dict(self.competition_state)

    def axis(self, axis, target, tolerance=12):
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
                # Near a waypoint, keep the key down until a fresh physics
                # telemetry sample confirms movement. A fixed short pulse can
                # land entirely between frames on a slower CI browser, making
                # a real input look like a collision.
                if abs(distance) <= 35:
                    pulse_started = time.monotonic()
                    previous_pulse_position = current
                    previous_state_received_at = self.state_received_at
                    while time.monotonic() < deadline:
                        self.page.wait_for_timeout(10)
                        state = self.position()
                        current = state[axis]
                        if abs(target - current) <= tolerance:
                            return
                        if self.state_received_at > previous_state_received_at:
                            previous_state_received_at = self.state_received_at
                            if abs(current - previous_pulse_position) >= 1.0:
                                break
                            previous_pulse_position = current
                        if time.monotonic() - pulse_started >= 0.5:
                            break
                    continue
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
                self.page.wait_for_timeout(150)
        raise AssertionError(f"Timed out walking to {axis}={target}: {self.position()}")

    def go(self, *waypoints):
        for axis, target in waypoints:
            self.axis(axis, target)

    def move_until_ready(self, key, expected_action):
        """Approach an interaction using normal input and the game's own readiness."""
        deadline = time.monotonic() + 15
        self.page.keyboard.down(key)
        try:
            while time.monotonic() < deadline:
                state = self.position()
                if state['ready'] and state['action'] == expected_action:
                    return
                self.page.wait_for_timeout(40)
        finally:
            self.page.keyboard.up(key)
        raise AssertionError(f"Interaction {expected_action} did not become ready: {self.position()}")

    def pursue_turtle(self, expected_action="送花", timeout=25):
        """Chase the live turtle using WASD until its nearby action is ready."""
        deadline = time.monotonic() + timeout
        keys_down = set()
        try:
            while time.monotonic() < deadline:
                state = self.position()
                if state["action"] == expected_action and state["ready"]:
                    return state
                if "turtle_x" not in state or "turtle_y" not in state:
                    raise AssertionError(f"Turtle telemetry is missing: {state}")
                dx = state["turtle_x"] - state["x"]
                dy = state["turtle_y"] - state["y"]
                desired = set()
                if abs(dx) > 4:
                    desired.add("d" if dx > 0 else "a")
                if abs(dy) > 4:
                    desired.add("s" if dy > 0 else "w")
                for key in keys_down - desired:
                    self.page.keyboard.up(key)
                for key in desired - keys_down:
                    self.page.keyboard.down(key)
                keys_down = desired
                self.page.wait_for_timeout(70)
            raise AssertionError(f"Could not approach turtle for {expected_action}: {self.position()}")
        finally:
            for key in keys_down:
                self.page.keyboard.up(key)
