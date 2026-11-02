shader_type canvas_item;
render_mode unshaded;
uniform vec2 radius_uv = vec2(0.04, 0.10);
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 content_scale = vec2(1.0);
uniform sampler2D silhouette : filter_linear, repeat_disable;
float alpha_at(vec2 point) {
	if (any(lessThan(point, vec2(0.0))) || any(greaterThan(point, vec2(1.0)))) {
		return 0.0;
	}
	return texture(silhouette, point).a;
}
void fragment() {
	// Expanded drawing quad leaves room for the halo outside the original image.
	vec2 point = (UV - vec2(0.5)) * content_scale + vec2(0.5);
	float center = alpha_at(point);
	float halo = 0.0;
	float rim = 0.0;
	for (int i = 0; i < 12; i++) {
		float angle = float(i) * 6.2831853 / 12.0;
		vec2 direction = vec2(cos(angle), sin(angle));
		halo += alpha_at(point + direction * radius_uv) / 12.0;
		rim = max(rim, alpha_at(point + direction * radius_uv * 0.38));
	}
	// Keep the center transparent; the existing soil remains fully visible.
	float edge = clamp(rim * 0.82 + halo * 0.65, 0.0, 1.0) * (1.0 - center);
	COLOR = vec4(1.0, 0.86, 0.40, edge * strength);
}
