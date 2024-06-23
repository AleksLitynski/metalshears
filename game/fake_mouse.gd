extends Sprite2D
class_name FakeMouse

var fake_mouse_visible: bool = false
var mouse_pos: Vector2 = Vector2.ZERO

func _ready():
	reset_mouse()
	
func _process(delta):
	if fake_mouse_visible and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		global_position = mouse_pos
	queue_redraw()
	visible = fake_mouse_visible

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		var new_pos = mouse_pos + event.relative
		if new_pos.x < 0 or new_pos.x > get_viewport_rect().size.x:
			new_pos.x = mouse_pos.x
		if new_pos.y < 0 or new_pos.y > get_viewport_rect().size.y:
			new_pos.y = mouse_pos.y
		mouse_pos = new_pos

func angle_from_center():
	var normalized_point = mouse_pos - screen_center()
	return normalized_point.angle()

func _draw():
	if fake_mouse_visible:
		draw_line(to_local(screen_center()), to_local(mouse_pos), Color(0.1, 0.2, 0.8, 0.7), 4.0, true)
	else:
		pass

func screen_center():
	return get_viewport_rect().size * 0.5
	
func reset_mouse():
	mouse_pos = screen_center() + Vector2(0, -screen_center().x * 0.5)
