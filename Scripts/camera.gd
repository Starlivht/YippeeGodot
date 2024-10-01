extends Camera2D

@export var target : Node2D
var directional_offset := 0.0
const PLAYER_VERTICAL_OFFSET = 60
const PLAYER_HORIZONTAL_OFFSET = 40
var shakeFade := 0.0005
var rng = RandomNumberGenerator.new()
var shake_strenght := 0.0

func _ready() -> void:
	if target:
		position_smoothing_enabled = false
		global_position = target.global_position
		global_position.y -= PLAYER_VERTICAL_OFFSET

func _process(delta: float) -> void:

	if not position_smoothing_enabled:
		position_smoothing_enabled = true
	
	if target:
		global_position = target.global_position
		if target.name == "Player":
			global_position.y -= PLAYER_VERTICAL_OFFSET
			directional_offset = move_toward(directional_offset, target.direction * PLAYER_HORIZONTAL_OFFSET, 50 * delta)
			global_position.x += directional_offset
	
	#shake stuff
	if shake_strenght > 0:
		shake_strenght = lerpf(shake_strenght, 0, 1 - pow(shakeFade, delta))
		offset = random_offset()

func apply_shake(strenght : float):
	shake_strenght = strenght

func random_offset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strenght, shake_strenght), rng.randf_range(-shake_strenght, shake_strenght))
