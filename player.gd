extends CharacterBody3D

@export var move_speed: float = 2.0
@export var jump_velocity: float = 10.0
@export var gravity: float = 30
@export var mouse_sensitivity: float = 0.003
@export var drag: float = 0.8

@export var movement_bob_speed: float = 70.0
@export var movement_bob_amount: float = 0.05
@export var camera_swerve: float = 10

var offset = 0
var movement_mount = 0
var look_rotation := Vector2.ZERO  # (yaw, pitch)

var last_raycast_hit: Object = null

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_rotation.x -= event.relative.x * mouse_sensitivity
		look_rotation.y = clamp(look_rotation.y - event.relative.y * mouse_sensitivity, -1.5, 1.5)

		# Apply rotations
		rotation.y = look_rotation.x  # Yaw (left/right)
		camera.rotation.x = look_rotation.y  # Pitch (up/down)
		
		

func _physics_process(delta: float) -> void:
	var input_dir = Vector3.ZERO
	
	movement_mount = abs(velocity.x) + abs(velocity.z)
	if not is_on_floor():
		movement_mount *= 0.8
	
	#print(movement_mount)
	offset = (movement_mount*sin(Time.get_ticks_msec()/movement_bob_speed))*movement_bob_amount
	camera.v_offset = offset
	camera.rotate_z(offset/camera_swerve)
	#print(offset)

	if Input.is_action_pressed("forward"):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("backward"):
		input_dir += transform.basis.z
	if Input.is_action_pressed("strafe-left"):
		input_dir -= transform.basis.x
	if Input.is_action_pressed("strafe-right"):
		input_dir += transform.basis.x

	input_dir.y = 0
	input_dir = input_dir.normalized()

	# Update horizontal velocity
	velocity.x += input_dir.x * move_speed
	velocity.z += input_dir.z * move_speed
	
	velocity.x *= drag
	velocity.z *= drag

	# Gravity and Jumping
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_pressed("jump"):
		velocity.y = jump_velocity
		

	move_and_slide()
	
	handle_raycast()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	elif event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func handle_raycast():
	if not $Camera3D/RayCast3D.is_colliding():
		level.look_text = ""
		stop_pointer(last_raycast_hit)
		return
	
	var coll = $Camera3D/RayCast3D.get_collider()
	
	
	if coll.has_meta("name"):
		level.look_text = coll.get_meta("name")
		start_pointer(coll)
		#coll.get_node(coll.get_meta("light")).modulate = Color.RED
	#print(coll.get_meta("name"))
	
	if last_raycast_hit != coll and last_raycast_hit != null:
		stop_pointer(last_raycast_hit)
	if last_raycast_hit != coll:
		level.look_text = ""
	
	last_raycast_hit = coll
	
func start_pointer(c):
	if c.has_meta("supports_outline"):
		if c.get_meta("supports_outline"):
			#coll.set_outline_visible(coll.get_node(coll.to_outline), true)
			c.highlight(c.get_node(c.to_outline))
	level.pointer_style = 0
	
func stop_pointer(c):
	if c != null:
			if c.has_meta("supports_outline"):
				if c.get_meta("supports_outline"):
					c.remove_highlight(c.get_node(c.to_outline))
	level.pointer_style = 1
