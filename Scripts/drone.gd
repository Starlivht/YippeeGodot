extends CharacterBody2D

var counter := 0.0
var target : Node2D = null
const SPEED := 200
var inRange = false;
@onready var health_component: Node2D = $HealthComponent

func _ready() -> void:
	return
	
func _physics_process(delta: float) -> void:
	counter += delta
	velocity.y = sin(counter * 3) * 20
	
	#horizontal movement
	if(target):
		var targetDir = target.global_position.x - global_position.x
		if(targetDir > 0 ): targetDir = 1  
		else: targetDir = -1
		
		if(inRange):
			velocity.x = lerpf(velocity.x, SPEED * (-targetDir), 1- pow(0.4, delta))
		else:
			velocity.x = lerpf(velocity.x, SPEED * targetDir, 1- pow(0.4, delta))
	
	move_and_slide()


func _on_player_check_body_entered(body: Node2D) -> void:
	target = body

func _on_range_check_body_entered(body: Node2D) -> void:
	inRange = true


func _on_range_check_body_exited(body: Node2D) -> void:
	inRange = false


func _on_health_component_hp_depleted() -> void:
	queue_free()
