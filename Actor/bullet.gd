extends Area2D

var direction = Vector2.RIGHT
var speed = 50
var damage = 1
var is_charged = false
@export var normal_hit_vfx: PackedScene
@export var charged_hit_vfx: PackedScene

func _ready():
	rotation = direction.angle()
	if is_charged:
		$AnimationPlayer.play("charged")
	
	else:
		$AnimationPlayer.play("play")
		
func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
		spawn_hit_vfx()
	queue_free()

func spawn_hit_vfx():
	var vfx_scene = charged_hit_vfx if is_charged else normal_hit_vfx
	if vfx_scene:
		var vfx = vfx_scene.instantiate()
		get_parent().add_child(vfx)
		vfx.global_position = global_position
		vfx.rotation = direction.angle()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
