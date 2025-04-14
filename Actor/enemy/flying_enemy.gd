extends CharacterBody2D

# Kecepatan gerakan musuh
@export var speed: float
# Jarak deteksi player
@export var detection_range: float = 100.0
# Damage yang diberikan ke player
@export var damage: int = 1
# Posisi terakhir player
var last_player_position: Vector2 = Vector2.ZERO
# Apakah player terdeteksi?
var is_player_detected: bool = false
# Apakah musuh sudah memberikan damage?
var has_given_damage: bool = false
@onready var texture = $Sprite2D.texture
# Referensi ke Area2D untuk deteksi dan damage
@onready var detection_area: Area2D = $DetectionArea
@onready var damage_area: Area2D = $damage

func _ready():
	# Mulai dengan gerakan acak
	start_random_movement()

func _physics_process(delta):
	if is_player_detected:
		# Jika player terdeteksi, kejar posisi terakhir player
		chase_player(delta)
	else:
		# Jika tidak, gerakan acak
		move_randomly(delta)

func start_random_movement():
	# Set kecepatan acak antara 20-40
	speed = randf_range(20, 40)
	# Set arah gerakan acak (kiri atau kanan)
	velocity.x = [-1, 1][randi() % 2] * speed

func move_randomly(delta):
	# Gerakan musuh berdasarkan velocity
	move_and_slide()

	# Jika musuh menabrak dinding, balik arah
	if is_on_wall():
		velocity.x *= -1

func chase_player(delta):
	# Hitung arah ke posisi terakhir player
	var direction = (last_player_position - global_position).normalized()
	# Gerakan musuh ke arah player
	velocity = direction * speed
	move_and_slide()

	# Jika musuh sudah dekat dengan posisi terakhir player
	if global_position.distance_to(last_player_position) < texture.get_width():
		kaboom()

func kaboom():
	print("meledak")
	# Cek apakah player masih di dalam DamageArea
	var bodies = damage_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):  # Ganti "Player" dengan nama node player Anda
			if not has_given_damage and body.has_node("Health_Component"):
				## Berikan damage ke player
				var v:Health_Component = body.get_node("Health_Component")
				v.take_damage(damage)
				has_given_damage = true
				print("meledak kena player")
	queue_free()

func _on_detection_area_body_entered(body):
	# Jika player masuk ke area deteksi dan belum terdeteksi sebelumnya
	if body.is_in_group("player") and not is_player_detected:  # Ganti "Player" dengan nama node player Anda
		is_player_detected = true
		last_player_position = body.global_position
		speed = 200
		print("Kepek musuh")


func _on_damage_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_player_detected:
		kaboom()
