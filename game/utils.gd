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

static func set_transparency(node: MeshInstance3D, target: float):
	for surf_idx in range(node.get_surface_override_material_count()):
		var current_surf: StandardMaterial3D = node.get_surface_override_material(surf_idx)
		if current_surf == null: continue
		current_surf.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		current_surf.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		current_surf.albedo_color.a = target
		node.set_surface_override_material(surf_idx, current_surf)
	for surf_idx in range(node.mesh.get_surface_count()):
		var current_surf: StandardMaterial3D = node.mesh.surface_get_material(surf_idx)
		if current_surf == null: continue
		current_surf.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		current_surf.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		current_surf.albedo_color.a = target
		node.mesh.surface_set_material(surf_idx, current_surf)

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
