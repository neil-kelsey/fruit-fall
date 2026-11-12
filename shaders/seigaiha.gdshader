shader_type canvas_item;
// Seigaiha (blue ocean wave) pattern on indigo lacquer.
uniform vec2 size = vec2(616.0, 856.0);
uniform float R = 26.0;
uniform vec4 bg : source_color = vec4(0.07, 0.13, 0.28, 1.0);
uniform vec4 line_col : source_color = vec4(0.27, 0.40, 0.64, 1.0);
uniform float vignette = 0.45;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 p = UV * size + vec2(0.0, 6.0);
	float best_y = -1e9;
	float best_d = 0.0;
	float j0 = floor(p.y / R);
	for (int dj = 0; dj <= 1; dj++) {
		float j = j0 + float(dj);
		float off = mod(j, 2.0) * R;
		float cy = j * R;
		float i0 = floor((p.x - off) / (2.0 * R));
		for (int di = 0; di <= 1; di++) {
			float cx = (i0 + float(di)) * 2.0 * R + off;
			float d = distance(p, vec2(cx, cy));
			if (d < R && cy > best_y) { best_y = cy; best_d = d; }
		}
	}
	float spacing = R / 4.0;
	float ring = abs(fract(best_d / spacing + 0.5) - 0.5) * spacing;
	float l = 1.0 - smoothstep(0.6, 1.6, ring);
	float edge = 1.0 - smoothstep(1.0, 2.4, R - best_d);
	float grain = hash(floor(p * 0.5)) * 0.06;
	vec3 c = mix(bg.rgb, line_col.rgb, max(l * 0.8, edge) * (0.85 + grain));
	vec2 uv = UV - 0.5;
	c *= 1.0 - vignette * dot(uv, uv) * 1.4;
	COLOR = vec4(c, 1.0);
}
