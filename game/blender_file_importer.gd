@tool
class_name BlendFileImporter
extends EditorScenePostImport

func _post_import(scene):
	# If we generate physics, a physics body will automatically be created
	# Throw away the physics body and hoist all child nodes up a level so we
	# can add our own physics body
	#hoist_physics_children(scene)
	
	return scene

func hoist_physics_children(node):
	for child in node.get_children():
		hoist_physics_children(child)
		if child is PhysicsBody3D:
			print("Found PhysicsBody3D: " + child.name)
			for physicsbody_child in child.get_children():
				physicsbody_child.get_parent().remove_child(physicsbody_child)
				node.add_child(physicsbody_child)
			child.get_parent().remove_child(child)
			child.queue_free()
