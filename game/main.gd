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
