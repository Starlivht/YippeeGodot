extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera


func _ready() -> void:
	GlobalSignals.explosion_created.connect(camera.apply_shake)


func _process(delta: float) -> void:
	pass


func frameFreeze(timeScale, duration):
	Engine.time_scale = timeScale
	await(get_tree().create_timer(duration * timeScale).timeout)
	Engine.time_scale = 1.0
