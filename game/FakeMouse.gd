extends Sprite2D


var fake_mouse_visible: bool = true
var mouse_pos: Vector2 = Vector2.ZERO

func _ready():
	mouse_pos = get_viewport_rect().size * 0.5

func _process(delta):
	if fake_mouse_visible and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		global_position = mouse_pos


func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		var new_pos = mouse_pos + event.relative
		if new_pos.x < 0 or new_pos.x > get_viewport_rect().size.x:
			new_pos.x = mouse_pos.x
		if new_pos.y < 0 or new_pos.y > get_viewport_rect().size.y:
			new_pos.y = mouse_pos.y
		mouse_pos = new_pos
	
