class_name CameraController
extends Node3D

#region Variables
@export_group("Speed", "speed_")
@export var speed_normal: float = 0.5
@export var speed_fast: float = 3.0
@export_group("Zoom", "zoom_")
@export var zoom_amount: float = 10.0
@export var zoom_max: float = 200.0
@export var zoom_min: float = 50.0
@export_group("Rotation","rotation_")
@export var rotation_amount: float = 2.0
@export_range(-180,180,0.001,"degrees") var rotation_vertical_max: float = -5
@export_range(-180,180,0.001,"degrees") var rotation_vertical_min: float = -80
@export_group("Inverted","inverted_")
@export var inverted_y_axis: bool = false
@export var inverted_x_axis: bool = false
@export var movement_time: float = 5.0
@export var ray_length: float = 3000.0
@export var frozen: bool = false
@export var follower: Node3D

var new_position: Vector3
var new_y_rotation: Quaternion
var new_x_rotation: float
var new_zoom: float
var drag_start_pos: Vector3
var drag_current_pos: Vector3
var drag_screen_start: Vector2
var drag_screen_current: Vector2
var init_y_rotation: Quaternion
var init_x_rotation: float
var _plane: Plane

@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var camera_arm: SpringArm3D = $SpringArm3D
#endregion


func _ready() -> void:
	new_position = global_position
	new_y_rotation = quaternion
	new_x_rotation = camera_arm.rotation_degrees.x
	new_zoom = camera_arm.spring_length
	_plane = Plane.PLANE_XZ


func _process(delta: float) -> void:
	if not frozen:
		_handle_movement_input()
		_handle_movement_mouse_input()
	_handle_zoom_input()
	_handle_rotation_input()
	_handle_rotation_mouse_input()

	_plane.d = global_position.y
	new_zoom = clampf(new_zoom, zoom_min, zoom_max)

	if follower:
		new_position = follower.global_position

	global_position = global_position.lerp(new_position, delta * movement_time)
	quaternion = quaternion.slerp(new_y_rotation.normalized(), delta * movement_time)
	camera_arm.spring_length = lerpf(camera_arm.spring_length, new_zoom, delta * movement_time)
	var rot_x: float = camera_arm.rotation_degrees.x
	camera_arm.rotation_degrees.x = lerpf(rot_x, new_x_rotation, delta * movement_time)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP):
			new_zoom -= zoom_amount
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN):
			new_zoom += zoom_amount
		get_viewport().set_input_as_handled()


func _handle_rotation_mouse_input() -> void:
	if Input.is_action_just_pressed(&"rotate_cam_mouse"):
		drag_screen_start = get_viewport().get_mouse_position()
		init_x_rotation = camera_arm.rotation_degrees.x
		init_y_rotation = quaternion

	if Input.is_action_pressed(&"rotate_cam_mouse"):
		drag_screen_current = get_viewport().get_mouse_position()
		var rot_y: float = (drag_screen_start.x - drag_screen_current.x) / 6
		var rot_x: float = (drag_screen_start.y - drag_screen_current.y) / 4
		if inverted_y_axis:
			rot_x = -rot_x
		if inverted_x_axis:
			rot_y = -rot_y
		new_y_rotation = init_y_rotation * Quaternion(Vector3.UP, deg_to_rad(rot_y))
		new_x_rotation = clampf(init_x_rotation + rot_x,
			rotation_vertical_min, rotation_vertical_max)


func cast_ray_to_plane(cam: Camera3D, ray_len: float) -> Vector3:
	var screen_point: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = cam.project_ray_origin(screen_point)
	var end: Vector3 = origin + cam.project_ray_normal(screen_point) * ray_len
	if _plane.intersects_segment(origin, end) is Vector3:
		return _plane.intersects_segment(origin, end)
	return Vector3.ZERO


func _handle_movement_mouse_input() -> void:
	if Input.is_action_just_pressed(&"move_cam_mouse"):
		var pos: Vector3 = cast_ray_to_plane(camera, ray_length)
		if pos:
			drag_start_pos = pos
	if Input.is_action_pressed(&"move_cam_mouse"):
		var pos: Vector3 = cast_ray_to_plane(camera, ray_length)
		if pos:
			drag_current_pos = pos
		new_position = global_position + drag_start_pos - drag_current_pos


func _handle_zoom_input() -> void:
	var axis: float = Input.get_axis(&"zoom_in",&"zoom_out")
	new_zoom += axis * zoom_amount


func _handle_rotation_input() -> void:
	var rot_y: float = Input.get_axis(&"rotate_cam_left", &"rotate_cam_right")
	var rot_x: float = Input.get_axis(&"rotate_cam_up", &"rotate_cam_down")
	new_y_rotation *= Quaternion(Vector3.UP, deg_to_rad(rot_y * rotation_amount))
	new_x_rotation = clampf(new_x_rotation + rot_x * rotation_amount,
		rotation_vertical_min, rotation_vertical_max)


func _handle_movement_input() -> void:
	if Input.is_action_pressed(&"rotate_cam_down") or \
			Input.is_action_pressed(&"rotate_cam_up") or \
			Input.is_action_pressed(&"rotate_cam_left") or \
			Input.is_action_pressed(&"rotate_cam_right"):
		return

	var movement_speed: float = speed_fast \
			if Input.is_action_pressed(&"fast_cam_moviment") \
			else speed_normal

	var dir: Vector2 = Input.get_vector(
			&"move_cam_left", &"move_cam_right",
			&"move_cam_forward", &"move_cam_backward")

	var new_transform: Vector3 = (transform.basis * -Vector3(dir.x, 0.0, dir.y))
	var speed_modfier: float = remap(new_zoom, zoom_min, zoom_max,
		1, zoom_max / zoom_min)

	new_position += new_transform.normalized() * movement_speed * speed_modfier
