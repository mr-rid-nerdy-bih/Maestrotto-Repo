extends CharacterBody2D

var speed: float = 20.0

@export var cam: Camera2D
@export var sprite: AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector("playerLeft","playerRight","playerUp","playerDown")
	direction = direction.normalized()
	velocity += direction * speed
	velocity *= 0.8
	
	if direction.x != 0:
		sprite.flip_h = direction.x < 0
	
	move_and_slide()
	
	if cam:
		cam.align()
