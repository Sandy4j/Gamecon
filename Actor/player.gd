extends CharacterBody2D

@export_group("Player")
@export var speed = 300.0
@export var jump_force = 450.0
@export var gravity = 980.0
@export var max_health = 100

var bullet_speed = 500.0
var fire_rate = 0.2
@export var bullet_scene: PackedScene

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var bullet_spawn = $Marker2D
@onready var fire_timer = $Timer

@export var bullet_spawn_right_position: Vector2
@export var bullet_spawn_left_position: Vector2

var health = max_health
var can_fire = true
var facing_right = true

func _ready():
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true
	
	if bullet_spawn_right_position == Vector2.ZERO:
		bullet_spawn_right_position = bullet_spawn.position
		bullet_spawn_left_position = Vector2(-bullet_spawn_right_position.x, bullet_spawn_right_position.y)
	
func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_force
		#animation_player.play("jump")
	
	var direction = Input.get_axis("left", "right")

	if direction > 0 and not facing_right:
		facing_right = true
		sprite.flip_h = false
		bullet_spawn.position = bullet_spawn_right_position
	elif direction < 0 and facing_right:
		facing_right = false
		sprite.flip_h = true
		bullet_spawn.position = bullet_spawn_left_position
	velocity.x = direction * speed

	#if is_on_floor():
		#if velocity.x != 0:
			#animation_player.play("run")
		#else:
			#animation_player.play("idle")
	
	if Input.is_action_pressed("shoot") and can_fire:
		shoot()

	move_and_slide()

func shoot():
	if not can_fire:
		return
	#animation_player.play("shoot")
	var bullet = bullet_scene.instantiate()
	bullet.global_position = bullet_spawn.global_position
	
	var direction = 1 if facing_right else -1
	bullet.direction = Vector2(direction, 0)
	bullet.speed = bullet_speed

	get_parent().add_child(bullet)
	can_fire = false
	fire_timer.start()

func take_damage(amount):
	health -= amount
	
	if health <= 0:
		die()
	#else:
		#animation_player.play("hurt")

func die():
	#animation_player.play("die")
	set_physics_process(false)
	#await animation_player.animation_finished
	queue_free()

func _on_timer_timeout() -> void:
	can_fire = true
