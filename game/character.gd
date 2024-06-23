class_name Character
extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var blade: Blade = %blade_area
@onready var blade_tilt: Node3D = $blade_tilt
@onready var barber: BarberCharacter = $barber

var walk_speed: float = 50
var run_speed: float = 200
var crouch_speed: float = 50
var roll_speed: float = 200
var roll_duration: float = 2.3667 * 0.5
var move_speed: float = walk_speed
var turn_to_face_input: bool = true
var sprint_timer_duration: float = 0.2
var in_pre_roll: bool = false

var input_vec: Vector2
var last_move_vec: Vector2

var jump_strength: float = 6
var jumping_from_run: bool = false
 

enum CHARACTER_STATES {
	CROUCH,
	WALK,
	RUN,
	JUMP,
	PRE_JUMP,
	POST_JUMP,
	ROLL,
	FROZEN
}
var current_state: CHARACTER_STATES = CHARACTER_STATES.WALK

func _ready():
	Utils.set_transparency_recursive(blade, 0.0)
	HoistPhysicsShapes.Hoist(self, barber)

var queued_dir: Vector2 = Vector2.ZERO
func set_dir(dir: Vector2):
	queued_dir = dir
	if current_state != CHARACTER_STATES.ROLL && current_state != CHARACTER_STATES.PRE_JUMP && current_state != CHARACTER_STATES.POST_JUMP:
		input_vec = dir

func _process(delta):
	if turn_to_face_input:
		var vec = last_move_vec
		vec.y = -vec.y
		rotation.y = lerp_angle(rotation.y, fmod(vec.angle() + deg_to_rad(90), TAU), 0.1)

func idling():
	return velocity.x == 0 && velocity.z == 0

func _physics_process(delta):
	var scaled_input = input_vec * move_speed * delta
	if current_state == CHARACTER_STATES.JUMP:
		# if jumping, maintain current velocity
		var air_control = 0.2 if !jumping_from_run else 0.1
		scaled_input.x = velocity.x + scaled_input.x * air_control * 0.5 # 20% air control
		scaled_input.y = velocity.z + scaled_input.y * air_control * 0.5
	if input_vec != Vector2.ZERO && turn_to_face_input:
		last_move_vec = input_vec
	velocity = Vector3(scaled_input.x, velocity.y - (gravity * delta), scaled_input.y)
	
	if idling() && current_state != CHARACTER_STATES.ROLL && current_state != CHARACTER_STATES.CROUCH && current_state != CHARACTER_STATES.PRE_JUMP && current_state != CHARACTER_STATES.JUMP && current_state != CHARACTER_STATES.POST_JUMP:
		barber.idle()
	elif current_state == CHARACTER_STATES.CROUCH && idling():
		barber.pause_crouch()
	elif current_state == CHARACTER_STATES.CROUCH:
		barber.crouch()
	elif current_state == CHARACTER_STATES.WALK:
		barber.walk()
	elif current_state == CHARACTER_STATES.RUN:
		barber.run()
	
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
			jump_starting_velo *= 0.9
			jump_starting_velo.x *= 0.05
			jump_starting_velo.z *= 0.05
		_:
			return
		
	current_state = CHARACTER_STATES.PRE_JUMP
	#velocity.x = 0
	#velocity.y = 0
	#input_vec = Vector2.ZERO
	move_speed = move_speed * 0.5
	barber.start_jump()
	get_tree().create_timer(0.25).timeout.connect(func():
		current_state = CHARACTER_STATES.JUMP
		velocity = jump_starting_velo
	)
	

func _end_jump():
	if current_state == CHARACTER_STATES.JUMP:
		current_state = CHARACTER_STATES.POST_JUMP
		barber.end_jump()
		get_tree().create_timer(0.2).timeout.connect(func():
			if jumping_from_run:
				_start_run()
			else:
				_start_walk()
			jumping_from_run = false
		)
		
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
	barber.roll()
	current_state = CHARACTER_STATES.ROLL
	move_speed = roll_speed * 0.1
	input_vec = Vector2(0, 1).rotated(-global_rotation.y)
	var roll_startup = 0.35
	var roll_cooldown = 0.5
	get_tree().create_timer(roll_startup).timeout.connect(func():
		move_speed = roll_speed * 1.75
		get_tree().create_timer(roll_cooldown).timeout.connect(func():
			move_speed = walk_speed
			get_tree().create_timer(0.2).timeout.connect(func():
				_end_roll()
			)
		)
	)

func _end_roll():
	if !turn_to_face_input:
		turn_to_face_input = true
		input_vec = Vector2.ZERO
	if current_state == CHARACTER_STATES.ROLL:
		input_vec = queued_dir
		if Input.is_action_pressed("roll"):
			_start_run()
		else:
			_start_walk()

# --- WALK AND RUN ---
func _start_run():
	in_pre_roll = false
	_end_crouch()
	current_state = CHARACTER_STATES.RUN
	barber.run()
	move_speed = run_speed

func _end_run():
	_start_walk()
	
func _start_walk():
	in_pre_roll = false
	current_state = CHARACTER_STATES.WALK
	barber.walk()
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
	move_speed = crouch_speed
	current_state = CHARACTER_STATES.CROUCH
	barber.crouch()

func _end_crouch():
	if current_state == CHARACTER_STATES.CROUCH:
		_start_walk()

# --- FREEZE MOVEMENT ---
func freeze_movement():
	move_speed = 0
	current_state = CHARACTER_STATES.FROZEN
	in_pre_roll = false

func unfreeze_movement():
	_start_walk()

func is_frozen():
	return current_state == CHARACTER_STATES.FROZEN

func do_slice():
	for body in blade.get_overlapping_bodies():
		if body.is_in_group("sliceable"):
			blade.slice_mesh(body)

func set_blade_angle(angle: float):
	blade.rotation.x = angle
	
func tilt_blade(angle: float):
	var new_angle = blade_tilt.rotation.x + angle 
	if new_angle <= deg_to_rad(25) and new_angle >= deg_to_rad(-20):
		blade_tilt.rotation.x = new_angle
