extends CharacterBody2D

enum{Patrol, Aiming}
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_component: Node = $HealthComponent
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var player_check: Area2D = $PlayerCheck
@onready var sprite_2d: Sprite2D = $Sprite2D
const BULLET = preload("res://Scenes/bullet.tscn")
@onready var shoot_timer: Timer = $ShootTimer

const SPEED := 50
var state := Patrol
var direction := -1
var target = null
var queue_patrol := false

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	match state:
		Patrol:
			#flip direction is they hit a wall or are about to fall off
			if is_on_wall() or not ray_cast_2d.is_colliding():
				direction *= -1
				ray_cast_2d.position.x *= -1
			velocity.x = direction * SPEED
			
		
		Aiming:
			velocity.x = 0
	move_and_slide()
	
	


func _on_health_component_hp_depleted() -> void:
	queue_free()


func _on_health_component_update_health(health: Variant) -> void:
	animation_player.play("hitflash")


func _on_shoot_timer_timeout() -> void:
	var bullet = BULLET.instantiate()
	bullet.target = target
	bullet.sender = self
	add_child(bullet)
	if queue_patrol:
		print("patrol ok")
		queue_patrol = false
		state = Patrol
		target = null
		shoot_timer.stop()


func _on_player_check_body_entered(body: Node2D) -> void:
	print("in")
	target = body
	state = Aiming
	queue_patrol = false;
	shoot_timer.start()


func _on_player_check_body_exited(body: Node2D) -> void:
	print("out")
	queue_patrol = true
