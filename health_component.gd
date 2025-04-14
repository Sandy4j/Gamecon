extends Control
class_name  Health_Component

@export var health:int
var cur_hp
@onready var hp_bar = $ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var v:Vector2
	var x:Sprite2D = self.get_parent().get_node("Sprite2D")
	v = x.texture.get_size()
	hp_bar.custom_minimum_size = Vector2(v.x,10)
	hp_bar.anchor_left = 0.4
	hp_bar.anchor_right = 0.4
	hp_bar.position = Vector2(-v.x/2,(-v.y/2)-(hp_bar.size.y+2))
	cur_hp = health
	hp_bar.max_value = health
	hp_bar.value = cur_hp
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_hp():
	hp_bar.value = cur_hp
	if cur_hp <= 0:
		get_parent().queue_free()

func take_damage(damage:int):
	cur_hp -= damage
	update_hp()
