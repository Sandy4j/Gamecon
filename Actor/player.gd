extends CharacterBody2D

signal state_changed(old_state, new_state)
signal health_changed(new_health)

@export_group("Player")
@export var speed = 300.0
@export var jump_force = 450.0
@export var gravity = 980.0
@export var max_health = 100
var bullet_speed = 500.0
var fire_rate = 0.5
@export var bullet_scene: PackedScene


@export_group("Dodge")
@export var dodge_speed = 600.0
@export var dodge_duration = 0.3
@export var dodge_cooldown = 0.1
@export var invincibility_frames = 0.5


@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var bullet_spawn = $Marker2D
@onready var fire_timer = $Timer
@onready var dodge_timer = $DodgeTimer
@onready var dodge_cooldown_timer = $DodgeCD
@onready var invincibility_timer = $Iframe
@onready var collision_shape = $CollisionShape2D

@export var bullet_spawn_right_position: Vector2
@export var bullet_spawn_left_position: Vector2

var health = max_health
var can_fire = true
var facing_right = true
var can_dodge = true
var is_invincible = false
var original_collision_layer
var original_collision_mask

enum State {IDLE, RUN, JUMP, FALL, DODGE, SHOOT, HURT, DEAD}
var current_state = State.IDLE
var previous_state = State.IDLE

func _ready():
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true
	
	if bullet_spawn_right_position == Vector2.ZERO:
		bullet_spawn_right_position = bullet_spawn.position
		bullet_spawn_left_position = Vector2(-bullet_spawn_right_position.x, bullet_spawn_right_position.y)

	original_collision_layer = collision_layer
	original_collision_mask = collision_mask
	
	change_state(State.IDLE)

func _physics_process(delta):
	match current_state:
		State.IDLE:
			process_idle_state(delta)
		State.RUN:
			process_run_state(delta)
		State.JUMP:
			process_jump_state(delta)
		State.FALL:
			process_fall_state(delta)
		State.DODGE:
			process_dodge_state(delta)
		State.SHOOT:
			process_shoot_state(delta)
		State.HURT:
			process_hurt_state(delta)
		State.DEAD:
			pass
	
	if Input.is_action_just_pressed("suicide"):
		die()
	
	if current_state != State.DODGE and !is_on_floor():
		velocity.y += gravity * delta
		
		if velocity.y > 0 and current_state != State.FALL:
			change_state(State.FALL)
	
	move_and_slide()

func process_idle_state(delta):
	var direction = Input.get_axis("left", "right")
	if direction != 0:
		handle_facing_direction(direction)
		velocity.x = direction * speed
		change_state(State.RUN)
	else:
		velocity.x = 0
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		change_state(State.JUMP)
	
	if Input.is_action_just_pressed("dodge") and can_dodge:
		change_state(State.DODGE)
	
	if Input.is_action_pressed("shoot") and can_fire:
		change_state(State.SHOOT)

func process_run_state(delta):
	var direction = Input.get_axis("left", "right")
	
	if direction == 0:
		change_state(State.IDLE)
		return
	
	handle_facing_direction(direction)

	velocity.x = direction * speed
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		change_state(State.JUMP)

	if Input.is_action_just_pressed("dodge") and can_dodge:
		change_state(State.DODGE)

	if Input.is_action_pressed("shoot") and can_fire:
		change_state(State.SHOOT)

func process_jump_state(delta):
	var direction = Input.get_axis("left", "right")
	if direction != 0:
		handle_facing_direction(direction)
		velocity.x = direction * speed
	else:
		velocity.x = 0
	
	if velocity.y > 0:
		change_state(State.FALL)

	if Input.is_action_just_pressed("dodge") and can_dodge:
		change_state(State.DODGE)

	if Input.is_action_pressed("shoot") and can_fire:
		change_state(State.SHOOT)
		
func process_fall_state(delta):
	var direction = Input.get_axis("left", "right")
	if direction != 0:
		handle_facing_direction(direction)
		velocity.x = direction * speed
	else:
		velocity.x = 0
		
	if is_on_floor():
		if velocity.x != 0:
			change_state(State.RUN)
		else:
			change_state(State.IDLE)
	else:
		if velocity.y > 0:
			animation_player.play("fall")
	
	if Input.is_action_just_pressed("dodge") and can_dodge:
		change_state(State.DODGE)
		
	if Input.is_action_pressed("shoot") and can_fire:
		change_state(State.SHOOT)

func process_dodge_state(delta):
	velocity.x = dodge_speed * (1 if facing_right else -1)

func process_shoot_state(delta):
	var direction = Input.get_axis("left", "right")
	if direction != 0:
		handle_facing_direction(direction)
		velocity.x = direction * speed
	else:
		velocity.x = 0

func process_hurt_state(delta):
	velocity.x *= 0.8

func change_state(new_state):
	previous_state = current_state
	current_state = new_state
	
	match previous_state:
		State.DODGE:
			end_dodge()
		State.SHOOT:
			pass
		State.HURT:
			sprite.modulate = Color(1, 1, 1)

	match new_state:
		State.IDLE:
			animation_player.play("idle")
		State.RUN:
			animation_player.play("run")
		State.JUMP:
			animation_player.play("jump")
			velocity.y = -jump_force
		State.FALL:
			if previous_state != State.JUMP:
				animation_player.play("fall")
		State.DODGE:
			start_dodge()
		State.SHOOT:
			perform_shoot()
		State.HURT:
			sprite.modulate = Color(1, 0, 0)
			await get_tree().create_timer(0.1).timeout
			
			if is_on_floor():
				if velocity.x != 0:
					change_state(State.RUN)
				else:
					change_state(State.IDLE)
			else:
				change_state(State.FALL)
		State.DEAD:
			die()

	emit_signal("state_changed", previous_state, current_state)

func handle_facing_direction(direction):
	if direction > 0 and not facing_right:
		facing_right = true
		sprite.flip_h = false
		bullet_spawn.position = bullet_spawn_right_position
	elif direction < 0 and facing_right:
		facing_right = false
		sprite.flip_h = true
		bullet_spawn.position = bullet_spawn_left_position

func start_dodge():
	can_dodge = false
	is_invincible = true

	collision_layer = 0
	collision_mask = 1

	animation_player.play("blink")
	await animation_player.animation_finished

	dodge_timer.wait_time = dodge_duration
	dodge_timer.start()
	
	invincibility_timer.wait_time = invincibility_frames
	invincibility_timer.start()

func end_dodge():
	if not is_invincible:
		collision_layer = original_collision_layer
		collision_mask = original_collision_mask

	dodge_cooldown_timer.wait_time = dodge_cooldown
	dodge_cooldown_timer.start()

func perform_shoot():
	if not can_fire:
		return
		
	animation_player.play("shoot")
	var bullet = bullet_scene.instantiate()
	bullet.global_position = bullet_spawn.global_position
	
	var direction = 1 if facing_right else -1
	bullet.direction = Vector2(direction, 0)
	bullet.speed = bullet_speed
	
	await animation_player.animation_finished
	get_parent().add_child(bullet)
	can_fire = false
	fire_timer.start()
	
	if is_on_floor():
		if velocity.x != 0:
			change_state(State.RUN)
		else:
			change_state(State.IDLE)
	else:
		change_state(State.FALL)

func take_damage(amount):
	if is_invincible or current_state == State.DEAD:
		return
		
	health -= amount
	emit_signal("health_changed", health)
	
	if health <= 0:
		change_state(State.DEAD)
	else:
		change_state(State.HURT)

func die():
	animation_player.play("death")
	set_physics_process(false)
	await animation_player.animation_finished
	queue_free()

func _on_timer_timeout() -> void:
	can_fire = true

func _on_dodge_timer_timeout():
	if is_on_floor():
		if velocity.x != 0:
			change_state(State.RUN)
		else:
			change_state(State.IDLE)
	else:
		change_state(State.FALL)

func _on_dodge_cd_timeout():
	can_dodge = true

func _on_iframe_timeout():
	is_invincible = false
	if current_state != State.DODGE:
		collision_layer = original_collision_layer
		collision_mask = original_collision_mask
