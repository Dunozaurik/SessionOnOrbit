shader_type spatial;

// Земля для открытого космоса на БЖД: континенты и океаны по шуму, полярные шапки,
// медленные облака, ночная сторона с огнями городов и голубая дымка атмосферы по краю.

uniform sampler2D continents : filter_linear_mipmap, repeat_enable;
uniform sampler2D clouds : filter_linear_mipmap, repeat_enable;
uniform sampler2D city_noise : filter_nearest, repeat_enable;
// Направление на Солнце в мировых координатах.
uniform vec3 sun_direction = vec3(-0.5, 0.45, 0.75);
uniform float land_level : hint_range(0.3, 0.7) = 0.52;

varying vec3 world_normal;

void vertex() {
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float height = texture(continents, UV).r;
	float land = smoothstep(land_level, land_level + 0.025, height);
	vec3 ocean_color = mix(vec3(0.02, 0.1, 0.4), vec3(0.06, 0.34, 0.8), smoothstep(0.15, land_level, height));
	vec3 land_color = mix(vec3(0.1, 0.42, 0.14), vec3(0.58, 0.46, 0.26), smoothstep(land_level, land_level + 0.2, height));
	vec3 color = mix(ocean_color, land_color, land);

	// Полярные шапки.
	float latitude = abs(UV.y - 0.5) * 2.0;
	float ice = smoothstep(0.8, 0.9, latitude + (height - 0.5) * 0.12);
	color = mix(color, vec3(0.95, 0.97, 1.0), ice);

	// Облака ползут по планете.
	float cloud_value = texture(clouds, UV + vec2(TIME * 0.003, 0.0)).r;
	float cloud = smoothstep(0.56, 0.78, cloud_value);
	color = mix(color, vec3(1.0), cloud * 0.85);

	// День и ночь.
	vec3 sun = normalize(sun_direction);
	float daylight = dot(world_normal, sun);
	float day = smoothstep(-0.12, 0.25, daylight);

	// Огни городов на ночной стороне: яркие точки на суше, без облаков.
	float city_value = texture(city_noise, UV * vec2(3.0, 1.5)).r;
	float cities = step(0.86, city_value) * land * (1.0 - ice) * (1.0 - cloud) * (1.0 - day);

	ALBEDO = color;
	ROUGHNESS = 0.85;
	METALLIC = 0.0;

	// Дымка атмосферы по краю диска и тусклое свечение ночной стороны.
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 atmosphere = vec3(0.3, 0.55, 1.0) * rim * (0.4 + 0.8 * day);
	vec3 night_glow = color * 0.08 * (1.0 - day);
	EMISSION = atmosphere + night_glow + vec3(1.0, 0.85, 0.45) * cities * 2.5;
}
