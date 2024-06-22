class_name Character
extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var walk_speed: float = 100
var run_speed: float = 200
var crouch_speed: float = 50
var roll_speed: float = 450
var roll_duration: float = 0.2
var move_speed: float = walk_speed
var turn_to_face_input: bool = true
var sprint_timer_duration: float = 0.2
var in_pre_roll: bool = false

var input_vec: Vector2
var last_move_vec: Vector2

var jump_strength: float = 5
var jumping_from_run: bool = false
 

enum CHARACTER_STATES {
	CROUCH,
	WALK,
	RUN,
	JUMP,
	ROLL,
	FROZEN
}
var current_state: CHARACTER_STATES = CHARACTER_STATES.WALK

func _ready():
	HoistPhysicsShapes.Hoist(self, $character_1)

var queued_dir: Vector2 = Vector2.ZERO
func set_dir(dir: Vector2):
	queued_dir = dir
	if current_state != CHARACTER_STATES.ROLL:
		input_vec = dir
		

func _process(delta):
	if turn_to_face_input:
		var vec = last_move_vec
		vec.y = -vec.y
		rotation.y = lerp_angle(rotation.y, fmod(vec.angle() + deg_to_rad(90), TAU), 0.1)
	
func _physics_process(delta):
	var scaled_input = input_vec * move_speed * delta
	if current_state == CHARACTER_STATES.JUMP:
		# if jumping, maintain current velocity
		scaled_input.x = velocity.x + scaled_input.x * 0.02 # 20% air control
		scaled_input.y = velocity.z + scaled_input.y * 0.02
	if input_vec != Vector2.ZERO && turn_to_face_input:
		last_move_vec = input_vec
	velocity = Vector3(scaled_input.x, velocity.y - (gravity * delta), scaled_input.y)
	if move_and_slide():
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider.is_in_group("pushable"):
				collider.apply_impulse(-collision.get_normal() * 0.1 * move_speed * delta, collision.get_position() - collider.global_position)
		
	if is_on_floor():
		velocity.y = 0
		_end_jump()
	
	

	
	#var children = ""
	#for c in get_children():
		#children += c.name + ", "
	#print(children)

func jump():
	# no direction: jump up and down
	# no direction, then air input: very short jump
	# input before jumping: jump in that direction
	# sprint input before jump: jump far in that direction
	# cannot air input to change directions
	# jump up is 0.8 character height
	# jump forwards is a parabola of that (idk, make it look reasonable)
	# must do sprint first
	
	# ON END JUMP, REMEMBER TO apply whatever movement the player hit in the air
	# input_vec = queued_dir
	_start_jump() # will fail if we aren't allowed to jump
	
		
func _start_jump():
	jumping_from_run = false
	var jump_starting_velo = Vector3(input_vec.x * move_speed * 0.02, jump_strength, input_vec.y * move_speed * 0.02)
	match current_state:
		CHARACTER_STATES.CROUCH:
			jump_starting_velo *= 0.7
		CHARACTER_STATES.WALK:
			jump_starting_velo *= 0.9
		CHARACTER_STATES.RUN:
			jumping_from_run = true
			jump_starting_velo *= 0.8
		_:
			return
		
	current_state = CHARACTER_STATES.JUMP
	velocity = jump_starting_velo
	

func _end_jump():
	if current_state == CHARACTER_STATES.JUMP:
		if jumping_from_run:
			_start_run()
		else:
			_start_walk()
	jumping_from_run = false

# --- ROLL ---
func roll_start():
	match current_state:
		CHARACTER_STATES.WALK:
			_do_pre_roll()
		CHARACTER_STATES.RUN:
			_do_pre_roll()
		CHARACTER_STATES.CROUCH:
			_do_pre_roll()
		CHARACTER_STATES.JUMP:
			jumping_from_run = true
			
func roll_end():
	jumping_from_run = false
	if in_pre_roll:
		_start_roll()
	if current_state == CHARACTER_STATES.RUN:
		_end_run()

func _do_pre_roll():
	in_pre_roll = true
	get_tree().create_timer(sprint_timer_duration).timeout.connect(func():
		if in_pre_roll:
			_start_run()
	)
	
func _start_roll():
	in_pre_roll = false
	_end_crouch()
	current_state = CHARACTER_STATES.ROLL
	move_speed = roll_speed
	if input_vec == Vector2.ZERO:
		turn_to_face_input = false
		input_vec = -Vector2(0, 1).rotated(-global_rotation.y)
		
	get_tree().create_timer(roll_duration).timeout.connect(func():
		_end_roll()
	)

func _end_roll():
	if !turn_to_face_input:
		turn_to_face_input = true
		input_vec = Vector2.ZERO
	if current_state == CHARACTER_STATES.ROLL:
		input_vec = queued_dir
		_start_walk()

# --- WALK AND RUN ---
func _start_run():
	in_pre_roll = false
	_end_crouch()
	current_state = CHARACTER_STATES.RUN
	move_speed = run_speed

func _end_run():
	_start_walk()
	
func _start_walk():
	in_pre_roll = false
	scale.y = 1.0
	current_state = CHARACTER_STATES.WALK
	move_speed = walk_speed
	
# --- CROUCH ---
func crouch():
	match current_state:
		CHARACTER_STATES.WALK:
			_start_crouch()
		CHARACTER_STATES.RUN:
			_start_crouch()
		CHARACTER_STATES.CROUCH:
			_end_crouch()
			
func _start_crouch():
	in_pre_roll = false
	scale.y = 0.7
	move_speed = crouch_speed
	current_state = CHARACTER_STATES.CROUCH

func _end_crouch():
	scale.y = 1.0
	if current_state == CHARACTER_STATES.CROUCH:
		_start_walk()

# --- FREEZE MOVEMENT ---
func freeze_movement():
	move_speed = 0
	current_state = CHARACTER_STATES.FROZEN
	in_pre_roll = false
	scale.y = 1.0

func unfreeze_movement():
	_start_walk()

var current_transparency: float = 1.0
var trans_tween: Tween
func tween_trans_to(target: float, duration: float = 0.5):
	if trans_tween != null:
		trans_tween.stop()
	trans_tween = get_tree().create_tween()
	trans_tween.tween_method(func(i):
		current_transparency = i
		set_transparency(i)
	, current_transparency, target, duration)
	trans_tween.play()
	
func set_transparency(trans: float = 1.0):
	for child in $character_1.get_children():
		if child is MeshInstance3D:
			for surf_idx in range(child.get_surface_override_material_count()):
				var current_surf: StandardMaterial3D = child.get_surface_override_material(surf_idx)
				if current_surf == null: continue
				current_surf.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				current_surf.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
				current_surf.albedo_color.a = trans
				child.set_surface_override_material(surf_idx, current_surf)
			for surf_idx in range(child.mesh.get_surface_count()):
				var current_surf: StandardMaterial3D = child.mesh.surface_get_material(surf_idx)
				if current_surf == null: continue
				current_surf.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				current_surf.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
				current_surf.albedo_color.a = trans
				child.mesh.surface_set_material(surf_idx, current_surf)

func is_frozen():
	return current_state == CHARACTER_STATES.FROZEN

func do_slice():
	var blade: Blade = $blade_area
	for body in blade.get_overlapping_bodies():
		if body.is_in_group("sliceable"):
			blade.slice_mesh(body)
			
