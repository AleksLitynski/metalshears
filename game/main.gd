class_name Main

extends Node3D

@onready var sound_manager:SoundManager = $SoundManager
@onready var fake_mouse: FakeMouse = %FakeMouse

func _ready():
	sound_manager.play_bgm(SoundManager.BGM.MAIN)
	
	var exterior_mesh : ArrayMesh = $arena_4/walls.mesh
	var mat_0: StandardMaterial3D = exterior_mesh.surface_get_material(0)
	mat_0.cull_mode = StandardMaterial3D.CULL_BACK
	exterior_mesh.surface_set_material(0, mat_0)
	
	%too_heavy.visible = false
	
	%ok_great.pressed.connect(func():
		unpause()
	)
	pause()


var goal_mass: float = 60
var scored_mass: float = 0
var time: float = 600
var game_done: bool = false

func pause():
	get_tree().paused = true
	%ui_panel.visible = false
	%pause_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func unpause():
	get_tree().paused = false
	%ui_panel.visible = true
	%pause_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$player.reset_move_vec()

func round_place(num,places):
	return (round(num*pow(10,places))/pow(10,places))

func flash_too_heavy():
	%too_heavy.visible = true
	%too_heavy.modulate.a = 1.0
	get_tree().create_tween().tween_method(func(i):
		%too_heavy.modulate.a = i
	, %too_heavy.modulate.a, 0.0, 0.5)
	get_tree().create_timer(0.5).timeout.connect(func():
		%too_heavy.visible = false
		%too_heavy.modulate.a = 1.0
	)
	
	
func _process(delta):
	time -= delta
	%time_label.text = str(int(time)) + " SECONDS REMAINING"
	%mass_label.text = str(round_place(scored_mass, 2)) + " / " + str(goal_mass) + " MASS ERASED"
	var hole: Area3D = $cleanup_hole
	for shape in hole.get_overlapping_bodies():
		if shape.is_in_group("sliceable"):
			var burst: GPUParticles3D = preload("res://particle_burst.tscn").instantiate()
			burst.draw_pass_1 = burst.draw_pass_1.duplicate()
			var mat = burst.draw_pass_1.surface_get_material(0).duplicate()
			mat.set_shader_parameter("particle_color", Color(255, 0, 0))
			burst.draw_pass_1.surface_set_material(0, mat)
			add_child(burst)
			var mesh: MeshInstance3D = shape.get_node("mesh")
			var global_center = mesh.to_global(mesh.get_aabb().get_center()) 
			#var current_offset = shape.global_position - global_center
			burst.global_position = global_center
			burst.emitting = true
			burst.one_shot = true
			get_tree().create_timer(1.0).timeout.connect(func():
				get_tree().root.remove_child(burst)
			)
			
			var shape_mass = shape.get_node("mesh").get_aabb().get_volume() * 3
			scored_mass += shape_mass
			
			shape.get_parent().remove_child(shape)
			shape.queue_free()

	if (time < 0 || scored_mass >= goal_mass) && !game_done:
		%big_message.text = "> Hey good job either beating the game or running out of time. \n> Why not just keep playing forever now?\n> (Just close the window when you're done)"
		game_done = true
		pause()
		
