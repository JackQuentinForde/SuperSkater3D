extends CharacterBody3D

const ACCEL = 4.0
const AIR_ACCEL = 2.0
const RIDE_SPEED = 4.0
const MAX_TURN_SPEED = 2.0
const JUMP_VELOCITY = 2.5
const TRICK_SPEED = 15.0

var direction = Vector3(1, 0, 0)
var lastRotation = 0
var _rotation = 0
var turnSpeed = 0.0
var rotationTimesSpeed = 0.0
var accel = 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var jump = false
var jumping = false
var kickFlip = false

#variables that are set in the ready function
var skateboard
var defaultBoardRotation
var animationPlayer

func _ready():
	skateboard = $Skateboard
	defaultBoardRotation = skateboard.rotation
	animationPlayer = get_node("Skateboard/AnimationPlayer")

func _physics_process(delta):
	setAcceleration()
	handleInput()
	setTurnSpeed(delta)
	applyRotation(delta)
	applyGravity(delta)
	jumpLogic()
	trickLogic(delta)
	moveLogic(delta)
	animate()
	move_and_slide()
	
func setAcceleration():
	if not is_on_floor():
		accel = AIR_ACCEL
	else:
		accel = ACCEL
		jumping = false

func handleInput():
	lastRotation = _rotation
	_rotation = Input.get_action_strength("player_left") - Input.get_action_strength("player_right")
	jump = is_on_floor() and Input.is_action_just_pressed("player_jump")
	if !is_on_floor() and Input.is_action_just_pressed("player_jump"):
		kickFlip = true

func setTurnSpeed(delta):
	if _rotation == lastRotation:
		turnSpeed += accel * delta
		if turnSpeed > MAX_TURN_SPEED:
			turnSpeed = MAX_TURN_SPEED
	else:
		turnSpeed = 0.0
	
func applyRotation(delta):
	rotationTimesSpeed = (_rotation * turnSpeed) * delta
	rotate_y(rotationTimesSpeed)

func applyGravity(delta):
	direction.y -= gravity * delta

func jumpLogic():
	if jump:
		direction.y = JUMP_VELOCITY
		jumping = true
		
func trickLogic(delta):
	if jumping and kickFlip:
		doAKickFlip(delta)
	else:
		kickFlip = false
		skateboard.rotation = defaultBoardRotation
		
func moveLogic(delta):
	direction = direction.rotated(Vector3.UP, rotationTimesSpeed)
	velocity = direction * RIDE_SPEED
	
func doAKickFlip(delta):
	skateboard.rotation.x += TRICK_SPEED * delta
	if skateboard.rotation_degrees.x > 360:
		skateboard.rotation_degrees.x = 0
		kickFlip = false
	
func animate():
	if jumping:
		if (animationPlayer.get_assigned_animation() != "Ollie" or 
				animationPlayer.get_current_animation_position() != animationPlayer.get_current_animation_length()):
				animationPlayer.play("Ollie")
	else:
		if animationPlayer.get_assigned_animation() == "Ollie":
			animationPlayer.set_assigned_animation("TurnRight")
		if _rotation < 0:
			if (animationPlayer.get_assigned_animation() != "TurnRight" or 
				animationPlayer.get_current_animation_position() != animationPlayer.get_current_animation_length()):
				animationPlayer.play("TurnRight")
		elif _rotation > 0:
			if (animationPlayer.get_assigned_animation() != "TurnLeft" or 
				animationPlayer.get_current_animation_position() != animationPlayer.get_current_animation_length()):
				animationPlayer.play("TurnLeft")
		elif animationPlayer.get_assigned_animation() != "Ollie":
			if animationPlayer.get_current_animation_position() != 0:
				animationPlayer.play_backwards(animationPlayer.get_assigned_animation())
