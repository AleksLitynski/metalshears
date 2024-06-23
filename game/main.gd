class_name Main

extends Node3D

@onready var sound_manager:SoundManager = $SoundManager
@onready var fake_mouse: FakeMouse = %FakeMouse

func _ready():
	sound_manager.play_bgm(SoundManager.BGM.MAIN)
