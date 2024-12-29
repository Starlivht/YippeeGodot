extends CharacterBody2D


const SPEED = 240.0
const SLIDE_SPEED = 900.0
const JUMP_VELOCITY = -500
const WALL_SLIDE_SPEED = 100
const WALL_JUMP_SPEED = 500
const GRAV = 1600.0
const DAMAGE := 2
const jump_strech := Vector2(0.7, 1.5)
var state := "Move"
var axis := 0.0
var direction := 1
var wall_jump_counter := 3
var buffer_wall_jump := false
var exit_wall_slide := 0.0
var attacking := false
var attack_cooldown := false
signal call_freeze_frame(timescale: float, duration: float)
var enemies_already_hit := []
var look_direction := 0
var squishable := false

@onready var health_component: Node2D = $HealthComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var attack_cooldown_timer: Timer = $AttackCooldown
@onready var hitbox: Area2D = $Hitbox
@onready var jump_buffer: Timer = $JumpBuffer
@onready var pulse: GPUParticles2D = $Pulse


func _ready() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	
	# helper code to get which way the character is facing
	if animated_sprite.flip_h == false:
		direction = 1
	else:
		direction = -1
	
	# handle state
	match state:
		"Move":
			# Add the gravity.
			if not is_on_floor():
				velocity.y += GRAV * delta
			
			
			# Check for jump buffer
			if Input.is_action_just_pressed("jump") and not is_on_floor():
				jump_buffer.start()
			
			# Handle jump.
			if (Input.is_action_just_pressed("jump") or not jump_buffer.is_stopped()) and (is_on_floor() or not coyote_timer.is_stopped()):
				velocity.y = JUMP_VELOCITY
				coyote_timer.stop()
				jump_buffer.stop()
				#strech 
				animated_sprite.scale = jump_strech
			if not Input.is_action_pressed("jump") and not is_on_floor() and velocity.y < velocity.y/2:
				velocity.y /= 2

			# Get the input direction and handle the movement/deceleration.
			axis = Input.get_axis("move_left", "move_right")
			if axis > 0:
				axis = 1
			elif axis < 0:
				axis = -1
			if is_on_floor():
				velocity.x = axis * SPEED
				wall_jump_counter = 3
			else:
				velocity.x = lerp(velocity.x, axis * SPEED, 1 - pow(0.0001, delta))
			
			# Handle attacks
			if Input.is_action_just_pressed("attack"):
				_attack()
			
			# Transition to slide state
			if Input.is_action_just_pressed("slide") and (is_on_floor() or not coyote_timer.is_stopped()) and not Input.is_action_just_pressed("jump"):
				state = "Slide"
				
				#pulse effect
				pulse.emitting = true
				if axis:
					pulse.position.x = -40 * axis
				else:
					pulse.position.x = -40 * direction
				if axis == 0:
					velocity.x = SLIDE_SPEED * direction
				else:
					velocity.x = SLIDE_SPEED * axis
				animated_sprite.scale = Vector2(1.6, .6)
				_end_attack()
			
			# Transition to wallslide state
			if is_on_wall_only() and wall_jump_counter > 0 and not attacking:
				if velocity.y >= 0:
					state = "WallSlide"
				elif Input.is_action_just_pressed("jump"):
					buffer_wall_jump = true
					state = "WallSlide"
				exit_wall_slide = 0
			
			
		"Slide":
			# Add softer gravity
			if not is_on_floor():
				velocity.y += GRAV/2.0 * delta
			
			# Get direction and slow speed
			velocity.x = lerp(velocity.x, SPEED * direction, 1 - pow(0.005, delta))
			
			# Transition to move state
			if abs(velocity.x) < abs(SPEED) + 30:
				state = "Move"
			if Input.is_action_just_pressed("jump"):
				state = "Move"
				velocity.y = JUMP_VELOCITY
				animated_sprite.scale = jump_strech
			if Input.is_action_just_pressed("attack") and not attack_cooldown:
				state = "Move"
				axis = Input.get_axis("move_left", "move_right")
				_set_flip_h()
				_attack()
		
		"WallSlide":
			velocity.y = WALL_SLIDE_SPEED
			velocity.x = 0
			# get wall normal
			var WallNormal := get_wall_normal()
			
			# Transition to move state
			if is_on_floor() or not is_on_wall():
				state = "Move"
			if (Input.is_action_just_pressed("jump") or buffer_wall_jump) and wall_jump_counter > 0:
				buffer_wall_jump = false
				wall_jump_counter -= 1
				state = "Move"
				# set speeds
				velocity.x = WALL_JUMP_SPEED * sign(WallNormal.x)
				velocity.y = JUMP_VELOCITY/1.2
				# flip side
				axis = sign(WallNormal.x)
				# streeeeetch
				animated_sprite.scale = jump_strech
			if wall_jump_counter <= 0:
				state = "Move"
			if (Input.is_action_pressed("move_left") and sign(WallNormal.x) < 0) or (Input.is_action_pressed("move_right") and sign(WallNormal.x) > 0):
				exit_wall_slide += delta
				if exit_wall_slide > 0.2:
					state = "Move"
					#push away from wall
					velocity.x = SPEED * sign(WallNormal.x)
					axis = sign(WallNormal.x)
			else:
				exit_wall_slide = 0
			
	
	# helper for coyote timer and sprite squashing
	var was_on_floor = is_on_floor()
	
	#         -----------------update position--------------
	move_and_slide()
	
	#coyote timer
	if not is_on_floor() and was_on_floor and velocity.y >= 0:
		coyote_timer.start()

	#        ------------------ update sprites -----------------
		
	#squash landing
	if is_on_floor() and not was_on_floor:
		if squishable:
			animated_sprite.scale = Vector2(1.3, 0.6)
		else:
			squishable = true

	#update sprite direction when not attacking
	if not attacking:
		_set_flip_h()
	
	if attacking:
		if animated_sprite.animation != "attack":
			animated_sprite.play("attack")
	elif state == "Move":
		#jump sprites
		if not is_on_floor():
			animated_sprite.play("jump")
		#idle or run
		else:
			if axis == 0:
				animated_sprite.play("idle")
			else:
				animated_sprite.play("run")
	elif state == "Slide":
		animated_sprite.play("slide")
	elif state == "WallSlide":
		var WallNormal := get_wall_normal()
		if WallNormal.x > 0:
			animated_sprite.flip_h = true
		else:
			animated_sprite.flip_h = false
		animated_sprite.play("wallslide")
		
	#reset squash and stretch
	animated_sprite.scale.x = move_toward(animated_sprite.scale.x, 1, 3 * delta)
	animated_sprite.scale.y = move_toward(animated_sprite.scale.y, 1, 3 * delta)
	
	# DEBUG
	
	
# attack handling function
func _attack():
	if not attack_cooldown:
		attacking = true
		attack_cooldown = true
		attack_cooldown_timer.start()
		# Call hitbox
		if animated_sprite.flip_h == true:
			hitbox.scale.x = -1
		else:
			hitbox.scale.x = 1
		hitbox.show()
		hitbox.process_mode = Node.PROCESS_MODE_INHERIT

# end attack handling function
func _end_attack() -> void:
	if animated_sprite.animation == "attack":
		attacking = false
		hitbox.hide()
		hitbox.process_mode = Node.PROCESS_MODE_DISABLED
		enemies_already_hit.clear()

# handle attack cooldown
func _on_attack_cooldown_timeout() -> void:
	attack_cooldown = false

# set sprite flip_h
func _set_flip_h():
	if axis > 0:
		animated_sprite.flip_h = false
	elif axis < 0:
		animated_sprite.flip_h = true

# ----- handle attack logic for enemies--------
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body not in enemies_already_hit:
		enemies_already_hit.append(body)
		body.health_component.take_damage(DAMAGE)
		call_freeze_frame.emit(0.05, .4)

# handle attack logic for bullets
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area not in enemies_already_hit:
		enemies_already_hit.append(area)
		area.target = area.sender
		area.sender = self
		area.speed *= 1.2
		area.change_trajectory()
		call_freeze_frame.emit(0.05, .5)
