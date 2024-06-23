class_name Main

extends Node3D

@onready var sound_manager:SoundManager = $SoundManager

# Called when the node enters the scene tree for the first time.
func _ready():
	sound_manager.play_bgm(SoundManager.BGM.MAIN)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
