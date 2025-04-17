extends CharacterBody2D

@export var speed: float
@export var detection_range: float = 100.0
@export var damage: int = 1
var last_player_position: Vector2 = Vector2.ZERO
var is_player_detected: bool = false
var has_given_damage: bool = false

@onready var texture = $Sprite2D.texture
@onready var detection_area: Area2D = $DetectionArea
@onready var damage_area: Area2D = $damage

func _ready():
	start_random_movement()

func _physics_process(delta):
	if is_player_detected:
		chase_player(delta)
	else:
		move_randomly(delta)

func start_random_movement():
	speed = randf_range(20, 40)
	velocity.x = [-1, 1][randi() % 2] * speed

func move_randomly(delta):
	move_and_slide()
	if is_on_wall():
		velocity.x *= -1

func chase_player(delta):
	var direction = (last_player_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	if global_position.distance_to(last_player_position) < texture.get_width():
		kaboom()

func kaboom():
	print("meledak")
	var bodies = damage_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			if not has_given_damage and body.has_node("Health_Component"):
				var v:Health_Component = body.get_node("Health_Component")
				v.take_damage(damage)
				has_given_damage = true
				print("meledak kena player")
	queue_free()

func _on_detection_area_body_entered(body):
	if body.is_in_group("player") and not is_player_detected:
		is_player_detected = true
		last_player_position = body.global_position
		speed = 200
		print("Kepek musuh")


func _on_damage_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_player_detected:
		kaboom()
