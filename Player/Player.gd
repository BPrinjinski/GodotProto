extends KinematicBody2D

const GRAVITY = 320
const SLIDE_SPEED = 30
const TERM_VELOCITY = 800
const ACCELERATION = 600
const MAX_SPEED = 100
const FRICTION = 800
const JUMP_MAX = .16
const JUMP_POWER = 18
const WALLJUMP_MAX = .30
const WALLJUMP_POWER = 80
const CLING_RAY_X = 7
const CLING_RAY_Y = -38.5

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

onready var leftWallRay = $LeftWallRay
onready var rightWallRay = $RightWallRay
onready var groundRayLeft = $GroundRayLeft
onready var groundRayRight = $GroundRayRight
onready var clingRay = $ClingRay

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")

var faceLeft = false
var state = IDLE
var velocity = Vector2.ZERO

var on_ground = false
var on_wall_left = false
var on_wall_right = false
var can_jump = false
var can_cling = true
var can_cling_timer = 0
var jump_time = 0
var walljump_time = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	animationTree.active = true;

func _physics_process(delta):	
	var horiz_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var jump_input = Input.is_action_pressed("ui_space")
	
	if(faceLeft):
		clingRay.transform.origin = Vector2(-1 * CLING_RAY_X, CLING_RAY_Y)
	else:
		clingRay.transform.origin = Vector2(CLING_RAY_X, CLING_RAY_Y)
	
	if(on_ground && state != JUMP):
		if(horiz_input == 0):
			state = IDLE
			if(faceLeft):
				animationState.travel("IdleLeft")
			else:
				animationState.travel("IdleRight")
		else:
			state = MOVE
	else:
		if((on_wall_left || on_wall_right) && state == FALL && can_cling && !clingRay.is_colliding()):
			state = CLING
		elif((on_wall_left || on_wall_right) && state != JUMP && state != CLING):
			state = SLIDE
		elif(velocity.y > 0):
			state = FALL
	
	if(jump_input):
		if((state == IDLE || state == MOVE) && can_jump):
			state = JUMP
			can_jump = false
			jump_time = 0
		if(state == SLIDE):
			state = WALLJUMP
			walljump_time = 0
			if(on_wall_left):
				faceLeft = false
			else:
				faceLeft = true
	
	match state:
		IDLE:
			if(!Input.is_action_pressed("ui_space")):
				can_jump = true
			idle_state(delta)
		MOVE:
			if(!Input.is_action_pressed("ui_space")):
				can_jump = true
			move_state(delta)
			if(faceLeft):
				animationState.travel("RunLeft")
			else:
				animationState.travel("RunRight")
		JUMP:
			if(faceLeft):
				animationState.travel("JumpLeft")
			else:
				animationState.travel("JumpRight")
			if(Input.is_action_pressed("ui_space") && jump_time < JUMP_MAX):
				velocity.y -= JUMP_POWER
				jump_time += delta
		FALL:
			move_state(delta)
			if(faceLeft):
				animationState.travel("FallLeft")
			else:
				animationState.travel("FallRight")
		SLIDE:
			slide_state(delta)
			if(on_wall_left):
				animationState.travel("SlideLeft")
			else:
				animationState.travel("SlideRight")
		WALLJUMP:
			walljump_state(delta)
			if(faceLeft):
				animationState.travel("JumpLeft")
			else:
				animationState.travel("JumpRight")
		CLING:
			cling_state(delta)
			if(faceLeft):
				animationState.travel("ClingLeft")
			else:
				animationState.travel("ClingRight")
	
	if(velocity.y > TERM_VELOCITY):
		velocity.y = TERM_VELOCITY
	elif(!on_ground && state != SLIDE && state != CLING):
		velocity.y = (velocity.y + (GRAVITY * delta))
	
	velocity = move_and_slide(velocity, Vector2(0,-1))
	
	on_ground = test_move(transform, Vector2(0,1))
	
	var groundLoc = 0
	var groundDist = 0
	var rayOrigin = 0
	
	# Because the collision object is smaller during jump and fall states, when landing,
	# we need to manually translate the object up and transition to the idle state
	# to avoid "pogo" behavior.
	if(on_ground && (state == FALL || state ==  JUMP)):
		#translate(Vector2(0, -4))
		if(groundRayLeft.is_colliding()):
			groundLoc = groundRayLeft.get_collision_point().y
			rayOrigin = groundRayLeft.global_transform.origin.y
			groundDist = 15 - (groundLoc - rayOrigin)
			translate(Vector2(0, -1 * groundDist))
		elif(groundRayRight.is_colliding()):
			groundLoc = groundRayRight.get_collision_point().y
			rayOrigin = groundRayRight.global_transform.origin.y
			groundDist = 15 - (groundLoc - rayOrigin)
			translate(Vector2(0, -1 * groundDist))
		if(faceLeft):
			animationState.travel("IdleLeft")
		else:
			animationState.travel("IdleRight")
	
	on_wall_left = leftWallRay.is_colliding()
	on_wall_right = rightWallRay.is_colliding()
	
	if(!can_cling && can_cling_timer > 0):
		can_cling_timer -= delta
	elif(!can_cling):
		can_cling = true

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
	velocity.y = 0
	apply_friction(delta)

func slide_state(delta):
	velocity.y = SLIDE_SPEED
	velocity.x = 0
	
	if(on_wall_left && Input.is_action_pressed("ui_right")):
		state = FALL
		velocity.x = ACCELERATION * delta
	elif(on_wall_right && Input.is_action_pressed("ui_left")):
		state = FALL
		velocity.x = -1 * ACCELERATION * delta

func walljump_state(delta):
	if(walljump_time < WALLJUMP_MAX):
		velocity.x = MAX_SPEED
		if(faceLeft):
			velocity.x *= -1
		velocity.y = WALLJUMP_POWER * -1
		
		walljump_time += delta
	else:
		state = FALL

func cling_state(delta):
	velocity.y = 0
	if(!clingRay.is_colliding()):
		transform.origin += Vector2(0, 1)
	
	if(Input.is_action_just_pressed("ui_down")):
		state = FALL
		can_cling = false
		can_cling_timer = .25

func apply_friction(delta):
	velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
