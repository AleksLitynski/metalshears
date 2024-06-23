extends Node
class_name Utils

static var tweens: Dictionary = {}
class TransparencyProps:
	var tween: Tween
	var transparency: float = 1.0

static func set_transparency_recursive(node: Node, target: float):
	if node is MeshInstance3D:
		set_transparency(node, target)
	for child in node.get_children():
		set_transparency_recursive(child, target)

static func set_mat_transparency(mat: Material, target: float) -> bool:
	if mat == null:
		return false
	if mat is StandardMaterial3D:
		if target == 1.0:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		else:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		mat.albedo_color.a = target
		return true
	if mat is ShaderMaterial:
		var a = mat.get_shader_parameter("force_alpha")
		if a != target:
			mat.set_shader_parameter("force_alpha", target)
		return false
	return false
	

static func set_transparency(node: MeshInstance3D, target: float):
	for surf_idx in range(node.get_surface_override_material_count()):
		var current_mat = node.get_surface_override_material(surf_idx)
		if set_mat_transparency(current_mat, target):
			node.set_surface_override_material(surf_idx, current_mat)
	if node.mesh:
		for surf_idx in range(node.mesh.get_surface_count()):
			var current_mat = node.mesh.surface_get_material(surf_idx)
			if set_mat_transparency(current_mat, target):
				node.mesh.surface_set_material(surf_idx, current_mat)

static func tween_transparency_recursive(node: Node, target: float, duration: float = 0.5):
	tween_transparency(node, target, duration, Utils.set_transparency_recursive)

static func tween_transparency(node: Node, target: float, duration: float = 0.5, set_method: Callable = set_transparency):
	if tweens.has(node):
		tweens[node].tween.stop()
	else:
		tweens[node] = TransparencyProps.new()

	tweens[node].tween = node.get_tree().create_tween()
	tweens[node].tween.tween_method(func(i):
		tweens[node].transparency = i
		set_method.call(node, i)
	, tweens[node].transparency, target, duration)
	tweens[node].tween.play()
