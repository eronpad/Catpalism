extends SpringArm3D

@export var mouse_sensibilidade: float = 0.005
@export var rotation_y_block: float = .8
var distancia: float = 5

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var x = get_parent().position
		rotation.x -= event.relative.y * mouse_sensibilidade
		# rotation.y -= event.relative.x * mouse_sensibilidade
		rotation.x = clamp(rotation.x, 0, 6)
		print(rotation.x)
