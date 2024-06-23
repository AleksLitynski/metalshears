class_name Player
extends Node3D


var character: Character
var camera: Camera3D

# Camera Position
var camera_angle: float = 0 # point on circle around the player
var moving_camera_offset: Vector3 = Vector3(1, 0.5, 0.0)
var zoomed_camera_offset: Vector3 = Vector3(0.3, 1.0, 0.5)
var camera_offset: Vector3 = moving_camera_offset # X is how far back the camera is, Y is how far up the camera is
var moving_camera_target_height: float = 0.45
var zoomed_camera_target_height: float = 0.45
var camera_target_height: float = moving_camera_target_height # distance above players head the camera should look (can be negative)


# camera speed
var camera_move_speed: float = INF
var camera_rotate_speed: float = 2.0
var snap_camera = true
var force_snap = false

var action_queue: Array = []

# input scaling
var camera_input_button_speed = 2.0

# Called when the node enters the scene tree for the first time.
func _ready():
	character = preload("res://character.tscn").instantiate()
	character.global_position.y = 2
	add_child(character)
	camera = %camera
	camera.make_current()
	force_snap = true
	update_camera(1)
	force_snap = false

func target_camera_position() -> Vector3:
	return character.global_position + Vector3(camera_offset.z, camera_offset.y, camera_offset.x).rotated(Vector3(0, 1, 0), camera_angle)

func camera_target() -> Vector3:
	return character.global_position + (Vector3.FORWARD.rotated(Vector3(0, 1, 0), camera_angle) * 1.0) + (Vector3.UP * camera_target_height)

func move_towards_velo(a: float, b: float, speed: float):
	if abs(a - b) > speed:
		return b
	if b < a:
		return a - speed
	if b > a:
		return a + speed

func rotate_towards_velo(a, b, speed: float):
	if abs(a - b) > speed:
		return b
	if b < a:
		return a - speed
	if b > a:
		return a + speed
	
func camera_angle_y():
	var ct = camera_target()
	var char_pos2d = Vector2(ct.x, ct.z)
	var cam_pos2d = Vector2(camera.global_position.x, camera.global_position.z)
	var camera_to_char = (char_pos2d - cam_pos2d).normalized()
	return atan2(camera_to_char.x, camera_to_char.y) + deg_to_rad(180)

func camera_angle_x():
	var cam_pos = camera.global_position + Vector3(0, 0, -camera_offset.z) 
	var ct = camera_target() + Vector3(0, camera_target_height, 0)
	return asin((ct.y - cam_pos.y)/cam_pos.distance_to(ct))

# Called every frame. 'delta' is the elapsed time since the previous frame.
var last_mouse_motion: Vector2 = Vector2.ZERO
func _process(delta):
	update_camera(delta)
	
	delta_mouse = Vector2.ZERO
	

func update_camera(delta):
	apply_camera_move(delta)
		
	if camera && character:
		var dist = camera.global_position.distance_to(character.global_position)
		var cms = camera_move_speed * delta if !force_snap else INF
		var crs = camera_rotate_speed * delta if !snap_camera && !force_snap else INF
		
		camera.global_position = camera.global_position.move_toward(target_camera_position(), cms)
		
		var prev_cam_y = camera.global_rotation.y
		camera.global_rotation.y = 0 # zero out the y so we can set the angle of without having to rotate anything weird
		camera.global_rotation.x = camera_angle_x() # rotate_toward(camera.global_rotation.x, camera_angle_x(), camera_rotate_speed * delta)
		camera.global_rotation.y = rotate_toward(prev_cam_y, camera_angle_y(), crs)

#x move:      WASD
#x Roll:      Shift
#x Run:		  Hold Shift
# Jump:       Space
#x Crouch: 	  C

#x Camera:    Arrow keys or mouse

# Right Hand: Mouse 1 / Mouse 2
# Left Hand:  E / R

# Interact:   F
# Use Item:   Q

func _input(event: InputEvent):
	# lock/unlock the camera
	if (event.is_action("ui_cancel")) || (Input.mouse_mode == Input.MOUSE_MODE_VISIBLE && event is InputEventMouseMotion):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event is InputEventMouseMotion:
		delta_mouse = event.relative
	
	handle_move_event(event)
	handle_action_event(event)

var delta_mouse: Vector2 = Vector2.ZERO
func apply_camera_move(delta: float):
	
	var current_input_vec = Vector2(Input.get_axis("camera_right", "camera_left"), Input.get_axis("camera_up", "camera_down"))
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		snap_camera = delta_mouse != Vector2.ZERO
		current_input_vec += delta_mouse * Vector2(-0.175, 0.1)
	else:
		snap_camera = false
		
	if character.is_frozen():
		# don't apply engine time scaling to this rotation, we want this to feel normal even in slomo
		character.set_blade_angle(current_input_vec.y * (delta / Engine.time_scale))
		current_input_vec.y = 0
		current_input_vec.x = (current_input_vec.x / Engine.time_scale) * 0.25

	camera_angle += current_input_vec.x * delta
	
	var scaled_y = current_input_vec.y * delta
	if (scaled_y < 0 && (camera_offset.y + scaled_y > 0.05)) || (scaled_y > 0 && (camera_offset.y + scaled_y < 2.3)):
		camera_offset.y += scaled_y
		camera_offset.x += scaled_y * 0.4
	
	camera_angle = fmod(camera_angle, TAU)

var move_vec: Vector2 = Vector2(0, 0)
func handle_move_event(event: InputEvent):
	if !character: return

	if event.is_action_pressed("move_forward"): move_vec.y -= 1
	if event.is_action_released("move_forward"): move_vec.y += 1
	if event.is_action_pressed("move_back"): move_vec.y += 1
	if event.is_action_released("move_back"): move_vec.y -= 1
	if event.is_action_pressed("move_left"): move_vec.x -= 1
	if event.is_action_released("move_left"): move_vec.x += 1
	if event.is_action_pressed("move_right"): move_vec.x += 1
	if event.is_action_released("move_right"): move_vec.x -= 1

	if character.is_frozen():
		character.set_dir(Vector2(0, -1).rotated(-camera.global_rotation.y))
	else:
		character.set_dir(move_vec.normalized().rotated(-camera.global_rotation.y))

	if event.is_action_pressed("jump"):
		character.jump()
	if event.is_action_pressed("roll"):
		character.roll_start()
	if event.is_action_released("roll"):
		character.roll_end()
	if event.is_action_released("crouch"):
		character.crouch()

func handle_action_event(event: InputEvent):
	if event.is_action_pressed("right_hand_primary"):
		if character.is_frozen():
			character.do_slice()
	if event.is_action_pressed("right_hand_secondary"):
		enter_cut_mode()
	if event.is_action_released("right_hand_secondary"):
		exit_cut_mode()
	if event.is_action("left_hand_primary"):
		print("left_hand_primary")
	if event.is_action("left_hand_secondary"):
		print("left_hand_secondary")
	if event.is_action("interact"):
		print("interact")
	if event.is_action("use_item"):
		print("use_item")

@onready var snap_timer: Timer = $Timer
func snap_time(duration: float, todo: Callable):
	snap_timer.stop()
	snap_timer.one_shot = true
	snap_timer.stop()
	for conn in snap_timer.timeout.get_connections():
		snap_timer.timeout.disconnect(conn["callable"])
	snap_timer.wait_time = duration
	snap_timer.timeout.connect(todo)
	snap_timer.start()

func enter_cut_mode():
	character.freeze_movement()
	camera_move_speed = 5.0
	character.set_dir(Vector2(0, -1).rotated(-camera.global_rotation.y))
	# zoom in the camera
	character.blade.rotation.x = PI*0.5
	camera_offset = zoomed_camera_offset
	camera_target_height = zoomed_camera_target_height
	Utils.tween_transparency_recursive(character.avatar, 0.3, 0.5)
	Utils.tween_transparency_recursive(character.blade, 1.0, 0.5)
	snap_time(0.5, func():
		Engine.set_time_scale(0.1)
	)
	get_tree().create_tween().tween_method(func(i):
		camera.fov = i
	, camera.fov, 60, 0.5)

func exit_cut_mode():
	character.unfreeze_movement()
	if move_vec == Vector2.ZERO:
		character.set_dir(Vector2.ZERO)
	character.move_speed = character.walk_speed
	# zoom out the camera
	camera_offset = moving_camera_offset
	camera_target_height = moving_camera_target_height
	Utils.tween_transparency_recursive(character.avatar, 1.0, 0.5)
	Utils.tween_transparency_recursive(character.blade, 0.0, 0.5)
	Engine.set_time_scale(1.0)
	snap_time(0.5, func():
		camera_move_speed = INF
	)
	get_tree().create_tween().tween_method(func(i):
		camera.fov = i
	, camera.fov, 75, 0.5)

