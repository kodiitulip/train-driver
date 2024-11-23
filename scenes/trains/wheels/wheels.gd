class_name TrainWheels
extends PathFollow3D

signal reached_track_head(wheel: TrainWheels, extra: float, is_forward: bool)
signal reached_track_tail(wheel: TrainWheels, extra: float, is_forward: bool)
signal moved(distance: float, leader: TrainWheels)

const TAILWARD: Directions = Directions.TAILWARD
const HEADWARD: Directions = Directions.HEADWARD

enum Directions {HEADWARD, TAILWARD}
var direction : Directions = TAILWARD

var follow_distance : float
var current_track : TrainTrack
var current_track_length : float

func set_track(track: TrainTrack, initial_position: float = 0.0) -> void:
	_disconnect_from_track()
	reparent(track, false)
	current_track = track
	current_track_length = track.curve.get_baked_length()
	progress = initial_position
	reached_track_head.connect(track.on_wheel_reached_head)
	reached_track_tail.connect(track.on_wheel_reached_tail)


# Place this wheel a specific distance behind another one
func follow(leader: TrainWheels, distance: float) -> void:
	follow_distance = distance
	direction = leader.direction
	set_track(leader.current_track)
	progress = leader.progress - distance
	leader.moved.connect(move_as_follower)


func unfollow(leader: TrainWheels) -> void:
	leader.moved.disconnect(move_as_follower)


# Move by some distance
func move(distance: float) -> void:
	if !current_track: return
	var original_offset: float = progress
	progress += distance if direction == TAILWARD else -distance
	_change_track_if_end(original_offset, distance)
	moved.emit(distance, self)

func move_as_follower(distance: float, leader: TrainWheels) -> void:
	if leader.progress > follow_distance and \
			leader.progress < leader.current_track_length - follow_distance:
		if leader.current_track != current_track:
			_put_on_leader_track(leader)
		_set_at_distance_from_leader(distance, leader)
	else:
		move(distance)

# Put on the same track, with same orientation, as the wheel it's following
func _put_on_leader_track(leader: TrainWheels) -> void:
	if leader.current_track != current_track:
		set_track(leader.current_track)
		direction = TAILWARD if leader.direction == TAILWARD else HEADWARD

# Position exactly at predetermined distance from the wheel it's following
func _set_at_distance_from_leader(distance: float, leader: TrainWheels) -> void:
	var original_offset: float = progress
	progress = leader.progress + (
		-follow_distance \
			if leader.direction == TAILWARD \
			else follow_distance
		)
	_change_track_if_end(original_offset, distance)
	moved.emit(distance, progress, direction, current_track, current_track_length)

# Signal that the wheel has reached the end of the segment
func _change_track_if_end(original_offset: float, distance_moved: float) -> void:
	if !current_track: return
	if progress_ratio <= 0.0:
		reached_track_head.emit(
			self,
			abs(original_offset - abs(distance_moved)),
			distance_moved > 0
			)
	elif progress_ratio >= 1.0:
		reached_track_tail.emit(
			self,
			original_offset + abs(distance_moved) - current_track_length,
			distance_moved > 0
			)

func _disconnect_from_track() -> void:
	if current_track:
		reached_track_head.disconnect(current_track.on_wheel_reached_head)
		reached_track_tail.disconnect(current_track.on_wheel_reached_tail)
	pass
