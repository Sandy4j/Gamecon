extends Area2D

var direction = Vector2.RIGHT
var speed = 50
var damage = 1

func _ready():
	rotation = direction.angle()
	$AnimationPlayer.play("play")

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
