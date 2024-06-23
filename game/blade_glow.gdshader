shader_type spatial;
render_mode cull_disabled, depth_draw_always;
uniform sampler2D depth_texture : source_color, hint_depth_texture;

varying mat4 CAMERA;

const float thickness = 0.08;

void vertex() {
	CAMERA = INV_VIEW_MATRIX;
}

void fragment() {
	
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	
	if (distance(view.xyz, VERTEX) < thickness / view.w)
	{
		ALPHA = smoothstep(view.z + 0.5, view.z, VERTEX.z);
		ALBEDO = COLOR.rgb;
	}
	else
	{
		ALPHA = 0.0;
	}
	
}
