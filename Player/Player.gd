extends KinematicBody2D

const GRAVITY = 220
const TERM_VELOCITY = 600
const ACCELERATION = 300
const MAX_SPEED = 200
const FRICTION = 800

enum {
	IDLE,
	MOVE,
	JUMP,
	FALL,
	CLING,
	SLIDE,
	BRACE
}

var state = IDLE
var velocity = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	if(velocity.y > TERM_VELOCITY):
		velocity.y = TERM_VELOCITY
	else:
		velocity.y = (velocity.y + (GRAVITY * delta)) 
	
	if(is_on_floor()):
		if(Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left") == 0):
			state = IDLE
		else:
			state = MOVE
	else:
		if(velocity.y > 0):
			state = FALL
	
	match state:
		IDLE:
			pass
		MOVE:
			move_state(delta)
		JUMP:
			pass
		FALL:
			move_state(delta)
	
	velocity = move_and_slide(velocity)

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector = input_vector.normalized()
	
	if(input_vector.x != 0):
		velocity.x = move_toward(velocity.x, input_vector.x * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
