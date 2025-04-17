extends CharacterBody2D
class_name Player

signal health_changed(new_health)
signal player_died

@export_group("Player")
@export var speed = 300.0
@export var jump_force = 450.0
@export var gravity = 980.0
@export var max_health = 5
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
var is_charging = false
var charge_time = 0.0
const CHARGE_THRESHOLD = 2.0
@export var damage = 1
@export var charged_bullet_damage = 2
@export var charged_bullet_speed_multiplier = 1.5

var health = max_health
var can_fire = true
var facing_right = true
var can_dodge = true
var is_invincible = false
var original_collision_layer
var original_collision_mask
var is_dodging = false
var is_shooting = false
var is_hurt = false
var is_dead = false

func _ready():
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true
	
	if bullet_spawn_right_position == Vector2.ZERO:
		bullet_spawn_right_position = bullet_spawn.position
		bullet_spawn_left_position = Vector2(-bullet_spawn_right_position.x, bullet_spawn_right_position.y)

	original_collision_layer = collision_layer
	original_collision_mask = collision_mask
	
	update_animation()

func _physics_process(delta):
	if is_dead:
		return
		
	if Input.is_action_just_pressed("suicide"):
		die()
		return
	
	if !is_on_floor() and !is_dodging:
		velocity.y += gravity * delta
	
	if !is_dodging and !is_dead:
		process_movement()
	elif is_dodging:
		velocity.x = dodge_speed * (1 if facing_right else -1)
	
	if is_charging:
		charge_time += delta
		#if charge_time >= CHARGE_THRESHOLD:
			#animation_player.play("charge_ready")
	
	process_actions()
	move_and_slide()
	update_animation()

func process_movement():
	var direction = Input.get_axis("left", "right")
	
	if direction != 0:
		handle_facing_direction(direction)
		velocity.x = direction * speed
	else:
		velocity.x = 0

func process_actions():
	if is_dodging or is_dead or is_hurt:
		return
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_force
	if Input.is_action_just_pressed("dodge") and can_dodge:
		start_dodge()
	if Input.is_action_pressed("shoot") and can_fire and !is_shooting:
		perform_shoot()

func update_animation():
	if is_dead:
		animation_player.play("death")
		return	
	if is_hurt:
		return
	if is_shooting:
		animation_player.play("shoot")
		return	
	if is_dodging:
		return
	
	if !is_on_floor():
		if velocity.y < 0:
			animation_player.play("jump")
		else:
			animation_player.play("fall")
	else:
		if velocity.x != 0:
			animation_player.play("run")
		else:
			animation_player.play("idle")

func start_charging():
	if can_fire and not is_shooting and not is_charging:
		is_charging = true
		charge_time = 0.0
		animation_player.play("charge")

func _input(event):
	if event.is_action_released("shoot") and is_charging:
		var is_charged = charge_time >= CHARGE_THRESHOLD
		perform_shoot(is_charged)
		is_charging = false
		$VFXAnimationPlayer.stop() # Hentikan VFX charging
		charge_time = 0.0

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
	is_dodging = true
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
	is_dodging = false
	
	if not is_invincible:
		collision_layer = original_collision_layer
		collision_mask = original_collision_mask

	dodge_cooldown_timer.wait_time = dodge_cooldown
	dodge_cooldown_timer.start()

func perform_shoot(is_charged = false):
	if not can_fire:
		return
		
	is_shooting = true
	var anim_name = "shoot"
	animation_player.play(anim_name)
	
	var bullet = bullet_scene.instantiate()
	bullet.global_position = bullet_spawn.global_position
	
	var direction = 1 if facing_right else -1
	bullet.direction = Vector2(direction, 0)
	bullet.speed = bullet_speed * (charged_bullet_speed_multiplier if is_charged else 1.0)
	bullet.damage = charged_bullet_damage if is_charged else damage
	bullet.is_charged = is_charged
	
	await animation_player.animation_finished
	get_parent().add_child(bullet)
	can_fire = false
	fire_timer.start()
	is_shooting = false

func take_damage(amount):
	if is_invincible or is_dead:
		return
		
	health -= amount
	emit_signal("health_changed", health)
	
	if health <= 0:
		die()
	else:
		is_hurt = true
		sprite.modulate = Color(1, 0, 0)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)
		is_hurt = false

func die():
	is_dead = true
	animation_player.play("death")
	await animation_player.animation_finished
	emit_signal("player_died")
	set_process(false)

func _on_timer_timeout() -> void:
	can_fire = true

func _on_dodge_timer_timeout():
	end_dodge()

func _on_dodge_cd_timeout():
	can_dodge = true

func _on_iframe_timeout():
	is_invincible = false
	if !is_dodging:
		collision_layer = original_collision_layer
		collision_mask = original_collision_mask
