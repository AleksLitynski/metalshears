class_name Blade
extends Area3D


var mesh_slicer = MeshSlicer.new()

var explosive_force: float = 200

func slice_mesh(target: CollisionObject3D):
	var shape: CollisionShape3D = target.get_node("shape")
	var mesh: MeshInstance3D = target.get_node("mesh")
	if shape == null || mesh == null:
		print("Target to slice must be a CollisionObject3D with a child collision shape and mesh. Why is this tagged 'sliceable' without the correct child node layout?")
		return
	
	var origional_aabb = mesh.mesh.get_aabb()
	var origional_volume = origional_aabb.get_volume()
	var origional_center = origional_aabb.get_center()
	
	var blade_transform = global_transform
	blade_transform.origin = target.to_local(blade_transform.origin)
	blade_transform.basis.x = target.to_local(blade_transform.basis.x+target.global_position)
	blade_transform.basis.y = target.to_local(blade_transform.basis.y+target.global_position)
	blade_transform.basis.z = target.to_local(blade_transform.basis.z+target.global_position)
	
	# generate two meshes
	var meshes = mesh_slicer.slice_mesh(blade_transform, mesh.mesh, preload("res://test_cube_interior.tres"))
		
	
	
	# make a copy of the collision object
	var target_copy = target.duplicate()
	target.get_parent().add_child(target_copy)
	
	mesh.mesh = meshes[0]
	target_copy.get_node("mesh").mesh = meshes[1]
	var mesh_0_aabb = meshes[0].get_aabb()
	var mesh_0_volume = mesh_0_aabb.get_volume()
	var mesh_0_center = mesh_0_aabb.get_center()
	
	shape.shape = meshes[0].create_convex_shape()
	target_copy.get_node("shape").shape = meshes[1].create_convex_shape()
	var mesh_1_aabb = meshes[1].get_aabb()
	var mesh_1_volume = mesh_1_aabb.get_volume()
	var mesh_1_center = mesh_1_aabb.get_center()
	
	if target is RigidBody3D:
		target.center_of_mass_mode = 1
		target.center_of_mass = target.to_local(mesh.to_global(calculate_center_of_mass(meshes[0])))
		target.mass = max(0.05, (target.mass / origional_volume) * mesh_0_volume)
		target.apply_central_force((mesh_0_center - origional_center).normalized() * explosive_force)
		
		target_copy.center_of_mass_mode = 1
		target_copy.center_of_mass = target.to_local(target_copy.get_node("mesh").to_global(calculate_center_of_mass(meshes[1])))
		target_copy.mass = max(0.05, (target_copy.mass / origional_volume) * mesh_1_volume)
		target_copy.apply_central_force((mesh_1_center - origional_center).normalized() * explosive_force / Engine.time_scale)
	
	
	if origional_volume >= 0.2:
		var host = target if mesh_0_volume > mesh_1_volume else target_copy
		var unique_points = {}
		for p in mesh_slicer.intersect_points:
			unique_points[p] = true
		var desired_points = []
		for up in unique_points.keys():
			desired_points.push_back(up)
		var blade_pos = host.to_local(global_position)
		desired_points.sort_custom(func(a: Vector3, b: Vector3): return a.distance_to(blade_pos) > b.distance_to(blade_pos))
		var max_ptrs = max(1, roundi(origional_volume * 10))
		if desired_points.size() > max_ptrs:
			desired_points = desired_points.slice(0, max_ptrs)
			
		(func():
			await get_tree().create_timer(0.01).timeout
			for pt in desired_points:
				var burst: GPUParticles3D = preload("res://particle_burst.tscn").instantiate()
				burst.draw_pass_1 = burst.draw_pass_1.duplicate()
				if randf() > 0.5:
					var mat = burst.draw_pass_1.surface_get_material(0).duplicate()
					mat.set_shader_parameter("particle_color", Color(255, 0, 0))
					burst.draw_pass_1.surface_set_material(0, mat)
				else:
					var mat = burst.draw_pass_1.surface_get_material(0).duplicate()
					mat.set_shader_parameter("particle_color", Color(70, 47, 20))
					burst.draw_pass_1.surface_set_material(0, mat)
					
				host.add_child(burst)
				burst.position = pt
				burst.emitting = true
				burst.one_shot = true
				get_tree().create_timer(1.0).timeout.connect(func():
					get_tree().root.remove_child(burst)
				)
				await get_tree().create_timer(0.05).timeout
		).call()
		
	
func calculate_center_of_mass(mesh:ArrayMesh):
	#Not sure how well this work
	var meshVolume = 0
	var temp = Vector3(0,0,0)
	for i in range(len(mesh.get_faces())/3):
		var v1 = mesh.get_faces()[i]
		var v2 = mesh.get_faces()[i+1]
		var v3 = mesh.get_faces()[i+2]
		var center = (v1 + v2 + v3) / 3
		var volume = (Geometry3D.get_closest_point_to_segment_uncapped(v3,v1,v2).distance_to(v3)*v1.distance_to(v2))/2
		meshVolume += volume
		temp += center * volume
	
	if meshVolume == 0:
		return Vector3.ZERO
	return temp / meshVolume
