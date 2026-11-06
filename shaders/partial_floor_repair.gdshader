shader_type canvas_item;

// Both paintings use the same canvas. Only changed artwork is revealed;
// unchanged masonry and equipment keep their original, seamless pixels.
uniform sampler2D broken_texture : source_color, filter_linear;
// xy = center in painting pixels; zw = radii around the work site.
uniform vec4 repair_regions[4];
uniform int repair_count = 3;
uniform float completed_stages = 0.0;
uniform bool reserve_beam_for_final = false;
uniform int floor_number = 1;
uniform vec2 canvas_size = vec2(1448.0, 1086.0);

float distance_to_segment(vec2 point, vec2 start, vec2 end) {
	vec2 span = end - start;
	float ratio = clamp(dot(point - start, span) / max(dot(span, span), 1.0), 0.0, 1.0);
	return length(point - (start + ratio * span));
}

bool is_unpowered_beam(vec2 pixel) {
	if (floor_number == 5) {
		// Keep the three glass surfaces visible while withholding the free-air ray.
		bool on_ray = distance_to_segment(pixel, vec2(365.0, 470.0), vec2(480.0, 315.0)) < 18.0
			|| distance_to_segment(pixel, vec2(480.0, 315.0), vec2(710.0, 260.0)) < 18.0
			|| distance_to_segment(pixel, vec2(710.0, 260.0), vec2(800.0, 115.0)) < 18.0;
		bool on_glass = length((pixel - vec2(480.0, 315.0)) / vec2(62.0, 73.0)) < 1.0
			|| length((pixel - vec2(710.0, 260.0)) / vec2(92.0, 100.0)) < 1.0
			|| length((pixel - vec2(800.0, 115.0)) / vec2(48.0, 55.0)) < 1.0;
		return on_ray && !on_glass;
	}
	if (floor_number == 6) {
		bool on_ray = distance_to_segment(pixel, vec2(790.0, 330.0), vec2(1210.0, 325.0)) < 22.0;
		bool on_glass = length((pixel - vec2(790.0, 330.0)) / vec2(155.0, 150.0)) < 1.0
			|| length((pixel - vec2(1210.0, 325.0)) / vec2(65.0, 65.0)) < 1.0;
		return on_ray && !on_glass;
	}
	return false;
}

void fragment() {
	vec4 repaired = texture(TEXTURE, UV);
	vec4 broken = texture(broken_texture, UV);
	vec3 delta = abs(repaired.rgb - broken.rgb);
	float change = smoothstep(0.025, 0.095, max(delta.r, max(delta.g, delta.b)));
	vec2 pixel = UV * canvas_size;
	// The fifth through seventh floors must not light a beam before their
	// final power-up. Intermediate steps only change glass and apparatus.
	if (reserve_beam_for_final && is_unpowered_beam(pixel)) {
		change = 0.0;
	}
	if (floor_number == 7 && reserve_beam_for_final && repaired.r > 0.76 && repaired.g > 0.52 && max(delta.r, delta.g) > 0.22) {
		change = 0.0;
	}
	float reveal = 0.0;
	for (int index = 0; index < 4; index++) {
		if (index >= repair_count) {
			break;
		}
		vec4 region = repair_regions[index];
		vec2 scaled = (pixel - region.xy) / max(region.zw, vec2(1.0));
		float inside = 1.0 - smoothstep(0.86, 1.0, length(scaled));
		float completed = clamp(completed_stages - float(index), 0.0, 1.0);
		reveal = max(reveal, inside * completed);
	}
	COLOR = vec4(repaired.rgb, repaired.a * change * reveal);
}
