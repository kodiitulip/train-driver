class_name TrainVehicle
extends Node3D

signal towed_mass_updated(mass_delta: float)

@export var wheel_distance: float = 1.1
@export var follow_distance: float = 0.5
@export var mass: float = 10.0
@export var initial_track: TrainTrack

var towed_mass: float = 0.0
var total_mass: float = mass

@onready var front_wheel : TrainWheels = $FrontWheels
@onready var back_wheel : TrainWheels = $BackWheels


func _ready() -> void:
	_setup_remote_transform.call_deferred(back_wheel)
	if initial_track:
		add_to_track(initial_track)


func _process(_delta: float) -> void:
	look_at(front_wheel.global_position, Vector3.UP, true)

# Place this vehicle (and all of its wheels) on the track
func add_to_track(track: TrainTrack, offset: float = wheel_distance) -> void:
	front_wheel.set_track(track)
	front_wheel.progress = offset
	back_wheel.follow(front_wheel, wheel_distance)

# Link another TrainVehicle to follow this one
func add_follower_car(car: TrainVehicle) -> void:
	car.add_to_track(back_wheel.current_track)
	car.front_wheel.follow(back_wheel, follow_distance)
	car.towed_mass_updated.connect(update_towed_mass)
	update_towed_mass(car.total_mass)

# Disconnect this car's signals from its followers
func remove_follower_car(car: TrainVehicle) -> void:
	car.front_wheel.unfollow(back_wheel)
	car.towed_mass_updated.disconnect(update_towed_mass)
	update_towed_mass(-car.total_mass)

# Share the knowledge of the new total mass
func update_towed_mass(mass_delta: float) -> void:
	towed_mass += mass_delta
	total_mass = mass + towed_mass
	towed_mass_updated.emit(mass_delta)


func _setup_remote_transform(node: Node3D) -> void:
	var remote: RemoteTransform3D = RemoteTransform3D.new()
	node.add_child(remote)
	remote.remote_path = get_path()
	remote.update_rotation = false
