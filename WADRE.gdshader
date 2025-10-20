shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// === UNIFORMS ===
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_foam : filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_refraction : filter_linear_mipmap, repeat_enable;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float roughness : hint_range(0, 1);
uniform float metallic : hint_range(0, 1);
uniform float specular : hint_range(0, 1);
uniform float normal_scale : hint_range(0, 2);
uniform float refraction : hint_range(-16, 16);

uniform vec4 metallic_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
uniform vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
uniform vec4 refraction_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);

// === TRIPLANAR CONTROL ===
uniform float uv1_blend_sharpness : hint_range(0.0, 8.0) = 2.0;
uniform vec3 uv1_scale = vec3(0.25);
uniform vec3 uv1_offset = vec3(0.0);

// === INTERNAL VARS ===
varying vec3 uv1_triplanar_pos;
varying vec3 uv1_power_normal;
varying vec3 local_pos;

// === FUNCTIONS ===
vec4 triplanar_texture(sampler2D tex, vec3 blend, vec3 pos) {
	vec4 samp = vec4(0.0);
	samp += texture(tex, pos.xy) * blend.z;
	samp += texture(tex, pos.xz) * blend.y;
	samp += texture(tex, pos.zy * vec2(-1.0, 1.0)) * blend.x;
	return samp;
}

// === VERTEX ===
void vertex() {
	vec3 normal = normalize(NORMAL);
	local_pos = VERTEX;

	// Remove mesh scale effect from triplanar position
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 scale_free = world_pos / vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	uv1_triplanar_pos = scale_free * uv1_scale + uv1_offset;

	// Blend weights
	uv1_power_normal = pow(abs(normal), vec3(uv1_blend_sharpness));
	uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));

	// === WAVE MOTION (scale-independent) ===
	float wave1 = sin(TIME * 2.15 + local_pos.x * -.5 + local_pos.z * .5);
	float wave2 = sin(TIME * 1.3 + local_pos.x * .1 + local_pos.z * .4);
	float wave3 = cos(TIME * 0.9 + local_pos.x * .09 - local_pos.z * -.4);
	float total_wave = (wave1 + wave2 + wave3) / 3.0;

	// Small, natural height offset
	VERTEX.y += total_wave * .5; // <- wave height (adjust)
}

// === FRAGMENT ===
void fragment() {
	float offset = TIME * 0.01;
	vec3 triplanar_pos = uv1_triplanar_pos + vec3(offset);

	vec4 albedo_tex = triplanar_texture(texture_albedo, uv1_power_normal, triplanar_pos);
	vec4 foam_tex = triplanar_texture(texture_foam, uv1_power_normal, triplanar_pos * 1.0);

	ALBEDO = albedo.rgb * albedo_tex.rgb + foam_tex.rgb * 1.0;

	float metallic_tex = dot(triplanar_texture(texture_metallic, uv1_power_normal, triplanar_pos), metallic_texture_channel);
	float roughness_tex = dot(triplanar_texture(texture_roughness, uv1_power_normal, triplanar_pos), roughness_texture_channel);

	METALLIC = metallic_tex * metallic;
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;

	vec3 normal_tex = triplanar_texture(texture_normal, uv1_power_normal, triplanar_pos).rgb;
	normal_tex = normal_tex * 2.0 - 1.0;
	NORMAL_MAP = normalize(normal_tex);
	NORMAL_MAP_DEPTH = normal_scale;

	vec3 ref_normal = normalize(mix(NORMAL, NORMAL_MAP, normal_scale));
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * dot(triplanar_texture(texture_refraction, uv1_power_normal, triplanar_pos), refraction_texture_channel) * refraction;
	float ref_amount = 1.0 - albedo.a * albedo_tex.a;

	EMISSION = textureLod(screen_texture, ref_ofs, ROUGHNESS * 8.0).rgb * ref_amount * EXPOSURE;
	ALBEDO *= 1.0 - ref_amount;
	ALPHA = 1.0;
}
