extends CharacterBody3D


@export var mouse_sensitivity : float = 5.0
@export var speed = 5.0
@export var jump_velocity = 4.5
@export var min_camera_yaw: float = -50.0
@export var max_camera_yaw: float = 45.0

@onready var navagent : NavigationAgent3D = $NavigationAgent3D
@onready var camera : Camera3D = $YawOrigin/PitchOrigin/SpringArm3D/Camera3D
@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var yaw_origin: Node3D = $YawOrigin
@onready var pitch_origin: Node3D = $YawOrigin/PitchOrigin

var next_path_position: Vector3
var last_valid_location_in_navmesh: Vector3
var gimble_y_rotation : float
var gimble_x_rotation : float
var jumping: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	## Respawn player upon falling off the map
	if last_valid_location_in_navmesh.distance_to(global_position) > 10:
		# put the player back where they fell
		global_position = last_valid_location_in_navmesh

	## Toggle mouse capture
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	## Apply mouse movement to gimble rotation
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		## Apply camera yaw rotation (y axis rotation)
		var current_y_rotation = yaw_origin.rotation.y
		yaw_origin.rotation.y = lerpf(
				current_y_rotation,
				current_y_rotation - gimble_y_rotation,
				mouse_sensitivity * delta
			)
		# Consume the yaw input
		gimble_y_rotation = 0
		
		## Apply camera pitch rotation (x axis rotation)
		var current_x_rotation = pitch_origin.rotation.x
		pitch_origin.rotation.x = lerpf(
				current_x_rotation, 
				clamp(
					current_x_rotation - gimble_x_rotation,
					deg_to_rad(min_camera_yaw),
					deg_to_rad(max_camera_yaw)
				),
				mouse_sensitivity * delta
			)
		# Consume the pitch input
		gimble_x_rotation = 0


func _physics_process(delta: float) -> void:
	## Do not query when the map has never synchronized and is empty.
	if NavigationServer3D.map_get_iteration_id(navagent.get_navigation_map()) == 0:
		return
	
	## Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	## Apply movement input
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") # TODO: investigate interesting behavoir later

	## Build heading from camera position data
	# Gather forward and right vectors
	var forward = camera.global_transform.basis.z
	var right = camera.global_transform.basis.x
	# Zero out basis y axis
	forward.y = 0
	right.y = 0
	# normalize the vectors
	forward = forward.normalized()
	right = right.normalized()
	# compute heading
	
	var heading = (forward * input_dir.y + right * input_dir.x).normalized()
	
	## Handle on floor movement
	if is_on_floor():
		## Apply the heading as the target position
		navagent.target_position = global_position + heading
		
		## Maintain last valid navmesh location for respawn incidents
		last_valid_location_in_navmesh = navagent.get_next_path_position()
		
		## Update body mesh to look at movement direction
		var look_at_target = Vector3(navagent.target_position.x, body_mesh.global_position.y, navagent.target_position.z)
		if body_mesh.global_position != look_at_target:
			body_mesh.look_at(look_at_target)
		
		## Calculate a velocity for movement
		var new_velocity = (last_valid_location_in_navmesh - global_position).normalized() * speed
		
		## Assign movement velocity
		velocity.x = new_velocity.x
		velocity.z = new_velocity.z
	
	## Handle in air movement for when player has jumped
	if jumping:
		## Update body mesh to look at movement direction
		var look_at_target = Vector3(body_mesh.global_position.x + heading.x, body_mesh.global_position.y, body_mesh.global_position.z + heading.z)
		if body_mesh.global_position != look_at_target:
			body_mesh.look_at(look_at_target)
		
		velocity.x = heading.x * speed
		velocity.z = heading.z * speed

	## Handle jump input
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity = heading * speed # Apply existing directional velocity to the jump
		velocity.y = jump_velocity # Apply jump velocity
		jumping = true

	## Handle landing after jump
	elif jumping && is_on_floor():
		jumping = false
		
	## Reset the x/z velocity when no input is recieved and player is on floor
	if input_dir == Vector2.ZERO && is_on_floor():
		velocity.x = 0
		velocity.z = 0
			
	move_and_slide()

func _input(event):
	## Handle mouse input
	if event is InputEventMouseButton:
		## Ensure mouse capture
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			return
		
		## Handle specific mouse button inputs
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT :
					print("Left mouse button pressed")
				MOUSE_BUTTON_MIDDLE:
					print("Middle mouse button pressed")
				MOUSE_BUTTON_RIGHT:
					print("Right mouse button pressed")
		
	
	## Handle mouse movement input
	if event is InputEventMouseMotion:
		## Add y rotation to camera gimble (Yaw)
		gimble_y_rotation = event.relative.normalized().x
		## Add x rotation to camera gimble (Pitch)
		# TODO: Clamp this ?
		gimble_x_rotation = event.relative.normalized().y
		