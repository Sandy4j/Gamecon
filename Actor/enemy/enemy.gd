extends CharacterBody2D

var max_hp= 10
var hp: int

@onready var hp_bar = $ProgressBar


func _ready() -> void:
	hp = max_hp
	hp_bar.max_value = max_hp
	hp_bar.value = hp

func _physics_process(delta:):
	if not is_on_floor():
		velocity += get_gravity() * delta

func take_damage(value:int):
	hp -= value
	hp_bar.value = hp
	if hp <= 0:
		queue_free()
