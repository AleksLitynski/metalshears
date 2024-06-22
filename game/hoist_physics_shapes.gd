class_name HoistPhysicsShapes
extends Node



static func Hoist(root: Node):
	var to_hoist = _get_all_collision_shape_children(root)
	for child in to_hoist:
		child.reparent(root)
		
static func _get_all_collision_shape_children(hoist_from: Node):
	var collision_shape_children = []
	for child in Array(hoist_from.get_children()):
		collision_shape_children.append_array(_get_all_collision_shape_children(child))
		if child is CollisionShape3D:
			collision_shape_children.append(child)
	return collision_shape_children
