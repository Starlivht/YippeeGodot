extends Node

@export var max_health: float = 10
var health: float
signal update_health(health)
signal hp_depleted()

func _ready() -> void:
	health = max_health

func take_damage(damage: float):
	#update health upon receiving damage
	health -= damage
	update_health.emit(health)
	
	#signal when hp is below zero
	if health <= 0:
		hp_depleted.emit()
	
