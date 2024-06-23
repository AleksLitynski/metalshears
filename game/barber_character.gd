class_name BarberCharacter
extends Node3D

@onready var player: AnimationPlayer = $Barber/AnimationPlayer
@onready var roll_fixer: AnimationPlayer = $RollFixer

func _ready():
	player.playback_default_blend_time = 0.3
	player.set_blend_time("wal", "run", 0.1)
	player.set_blend_time("roll", "walk", 0.2)
	player.set_blend_time("roll", "run", 0.2)
	#player.set_blend_time("jump", "run", 1.5)
	#player.set_blend_time("jump", "walk", 1.5)
	idle()

var force: bool = false

func walk():
	blend_into_anim("walk", true, 1.5)

func idle():
	blend_into_anim("idle", true, 1)

func run():
	blend_into_anim("run", true, 1)

func start_jump():
	blend_into_anim("jump", false, 2.0)
	get_tree().create_timer(0.4).timeout.connect(func():
		if current_anim == "jump":
			# run the anim at 1/5th speed. If we fall for too long, it'll mess up, but it looks way more natural than just pausing
			player.speed_scale = 0.2
	
			get_tree().create_timer(0.3).timeout.connect(func():
				if current_anim == "jump":
					player.speed_scale = 0.0
			)
	)

func end_jump():
	if current_anim == "jump":
		player.speed_scale = 2.0

func roll():
	blend_into_anim("roll", false, 2.0)
	roll_fixer.play("roll_fix", -1, 2.0)

func pause_crouch():
	var crouch_pause_speed = 0.01
	if player.speed_scale != crouch_pause_speed: force = true
	blend_into_anim("crouch", true, crouch_pause_speed)
	force = false

func crouch():
	if player.speed_scale != 1: force = true
	blend_into_anim("crouch", true, 1)
	force = false

var current_anim: String
func blend_into_anim(name: String, loop: bool, speed: float):
	if current_anim == name && !force: return
	player.speed_scale = speed
	current_anim = name
	var anim: Animation = player.get_animation(name)
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	player.play(name, -1)
