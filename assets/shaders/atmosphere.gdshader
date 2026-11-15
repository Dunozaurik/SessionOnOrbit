shader_type spatial;
render_mode unshaded, blend_add, cull_front, depth_draw_never;

// Светящаяся голубая дымка вокруг планеты: рисуется внутренней стороной чуть большей сферы.

uniform vec4 glow_color : source_color = vec4(0.3, 0.55, 1.0, 1.0);
uniform float power : hint_range(0.5, 6.0) = 2.0;
uniform float strength : hint_range(0.0, 3.0) = 1.2;

void fragment() {
	float edge = pow(clamp(dot(-NORMAL, VIEW), 0.0, 1.0), power);
	ALBEDO = glow_color.rgb * strength;
	ALPHA = edge;
}
