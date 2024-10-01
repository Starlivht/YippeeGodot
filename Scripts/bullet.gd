extends Area2D

var target := Node2D
var sender := Node2D
var speed := 2500
var trajectory : Vector2
const EXPLOSION = preload("res://Scenes/explosion.tscn")
var explosion_strenght = 20

func _ready() -> void:
	if target:
		change_trajectory()
	
func _process(delta: float) -> void:
	position.x += trajectory.x * speed * delta
	position.y += trajectory.y * speed * delta
	
func change_trajectory() -> void:
	trajectory = (target.global_position - global_position).normalized()


func _on_self_destruct_timeout() -> void:
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body == target:
		#EXPLODEEEE
		var explosion = EXPLOSION.instantiate()
		explosion.global_position = body.global_position
		explosion.emitting = true
		get_tree().current_scene.add_child(explosion)
		GlobalSignals.explosion_created.emit(explosion_strenght)
		
		#Kill
		body.health_component.take_damage(1)
