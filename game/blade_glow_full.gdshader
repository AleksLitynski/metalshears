// NOTE: Shader automatically converted from Godot Engine 4.2.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix,depth_draw_always,cull_disabled,diffuse_burley,specular_schlick_ggx,depth_prepass_alpha;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform float point_size : hint_range(0,128);
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_metallic : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r,filter_linear_mipmap,repeat_enable;
uniform float specular;
uniform float metallic;
varying vec3 uv1_triplanar_pos;
uniform float uv1_blend_sharpness;
varying vec3 uv1_power_normal;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

uniform float force_alpha = 1.0;

uniform sampler2D depth_texture : source_color, hint_depth_texture;

varying mat4 CAMERA;
const float thickness = 0.1;



void vertex() {
	CAMERA = INV_VIEW_MATRIX;
	vec3 normal = NORMAL;
	TANGENT = vec3(0.0,0.0,-1.0) * abs(normal.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(normal.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(normal.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0,1.0,0.0) * abs(normal.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(normal.y);
	BINORMAL+= vec3(0.0,1.0,0.0) * abs(normal.z);
	BINORMAL = normalize(BINORMAL);
	uv1_power_normal=pow(abs(NORMAL),vec3(uv1_blend_sharpness));
	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
	uv1_power_normal/=dot(uv1_power_normal,vec3(1.0));
	uv1_triplanar_pos *= vec3(1.0,-1.0, 1.0);
	
}

vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}

void fragment() {
	vec4 albedo_tex = triplanar_texture(texture_albedo,uv1_power_normal,uv1_triplanar_pos);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	float metallic_tex = dot(triplanar_texture(texture_metallic,uv1_power_normal,uv1_triplanar_pos),metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_tex = dot(triplanar_texture(texture_roughness,uv1_power_normal,uv1_triplanar_pos),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;
	
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	
	if (distance(view.xyz, VERTEX) < (thickness / view.w) * 0.2)
	{
		ALPHA = 1.0;
		ALBEDO = vec3(0.2, 0.3, 1.0);
		EMISSION = vec3(0.2, 0.2, 0.9) * 1.0;
	}
	else
	{
		if (distance(view.xyz, VERTEX) < thickness / view.w)
		{
			ALPHA = 1.0;
			ALBEDO *= 20.0;
			EMISSION = vec3(0.2, 0.2, 0.9) * 0.5;
		}
		else if(distance(view.xyz, VERTEX) < (thickness / view.w) * 30.0)
		{
			ALPHA = (smoothstep(view.z + 0.8, view.z, VERTEX.z) * 1.0);
		}
		else {
			ALPHA = 0.0;
		}
		
		ALPHA *= albedo.a * albedo_tex.a;
		ALPHA *= (sin(TIME * 3.0 + 0.3)*0.5 + 1.0) * 2.0;
		ALBEDO *= (sin(TIME * 3.0) * 0.5 + 1.0) * 0.5;
	}
	
	BACKLIGHT = vec3(5.0);
	ALPHA *= force_alpha;

}
