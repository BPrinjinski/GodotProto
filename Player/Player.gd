extends KinematicBody2D

const GRAVITY = 320
const TERM_VELOCITY = 800
const ACCELERATION = 600
const MAX_SPEED = 100
const FRICTION = 800
const JUMP_MAX = .16
const JUMP_POWER = 18

enum {
	IDLE,
	MOVE,
	JUMP,
	WALLJUMP,
	FALL,
	CLING,
	SLIDE,
	BRACE
}

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")

var faceLeft = false
var state = IDLE
var velocity = Vector2.ZERO

var can_jump = false
var jump_time = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	animationTree.active = true;

func _physics_process(delta):
	if(velocity.y > TERM_VELOCITY):
		velocity.y = TERM_VELOCITY
	else:
		velocity.y = (velocity.y + (GRAVITY * delta)) 
	
	var horiz_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	if(is_on_floor()):
		if(horiz_input == 0):
			state = IDLE
			if(faceLeft):
				animationState.travel("IdleLeft")
			else:
				animationState.travel("IdleRight")
		else:
			state = MOVE
			if(horiz_input > 0):
				faceLeft = false
				animationState.travel("RunRight")
			else:
				faceLeft = true
				animationState.travel("RunLeft")
	else:
		if(velocity.y > 0):
			state = FALL
	
	if(Input.is_action_pressed("ui_space")):
		if((state == IDLE || state == MOVE) && can_jump):
			state = JUMP
			can_jump = false
			jump_time = 0
	
	match state:
		IDLE:
			if(!Input.is_action_pressed("ui_space")):
				can_jump = true
			idle_state(delta)
		MOVE:
			if(!Input.is_action_pressed("ui_space")):
				can_jump = true
			move_state(delta)
		JUMP:
			if(Input.is_action_pressed("ui_space") && jump_time < JUMP_MAX):
				velocity.y -= JUMP_POWER
				jump_time += delta
			else:
				state = FALL
		FALL:
			move_state(delta)
	
	velocity = move_and_slide(velocity, Vector2(0,-1))

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector = input_vector.normalized()
	
	if(input_vector.x < 0):
		faceLeft = true
	elif(input_vector.x > 0):
		faceLeft = false
	
	if(input_vector.x != 0):
		velocity.x = move_toward(velocity.x, input_vector.x * MAX_SPEED, ACCELERATION * delta)
	else:
		apply_friction(delta)

func idle_state(delta):
	apply_friction(delta)
	
func apply_friction(delta):
	velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
