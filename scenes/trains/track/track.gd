@tool
class_name TrainTrack
extends Path3D

signal wheel_reached_head(wheel: TrainWheels, extra: float, is_forward: bool)
signal wheel_reached_tail(wheel: TrainWheels, extra: float, is_forward: bool)

const TAIL: Sides = Sides.TAIL
const HEAD: Sides = Sides.HEAD

enum Sides {
	TAIL,
	HEAD,
}

@export var track_mesh: Mesh
@export_range(0.001, 2.0, 0.1, "or_greater") var crosstie_distance: float = 1.0:
	set(value):
		crosstie_distance = maxf(value, 0.001)
		_update_end_points.call_deferred()

var curve_points: PackedVector3Array = []

@onready var tail: PathFollow3D = $Tail
@onready var head: PathFollow3D = $Head
@onready var multi_mesh: MultiMeshInstance3D = $MultiMeshInstance3D


func _ready() -> void:
	_update_end_points()
	set_process(Engine.is_editor_hint())
	curve.changed.connect(_update_end_points)


func _process(_delta: float) -> void:
	if curve_points != curve.get_baked_points():
		_update_end_points()


func link_track(other_track: TrainTrack, from_side: Sides, to_side: Sides) -> void:
	var from: Signal = wheel_reached_head \
		if from_side == HEAD else wheel_reached_tail
	var to: Callable = other_track.enter_from_head \
		if to_side == HEAD else other_track.enter_from_tail
	from.connect(to)

# A wheel enters from the head side
func enter_from_head(wheel: TrainWheels, extra: float, is_forward: bool) -> void:
	wheel.set_track(self)
	wheel.progress = extra
	wheel.direction = TrainWheels.TAILWARD if is_forward else TrainWheels.HEADWARD

# A wheel enters from the tail side
func enter_from_tail(wheel: TrainWheels, extra: float, is_forward: bool) -> void:
	wheel.set_track(self)
	wheel.progress_ratio = 1
	wheel.progress -= extra
	wheel.direction = TrainWheels.HEADWARD if is_forward else TrainWheels.TAILWARD

# The wheel has reached the head
func on_wheel_reached_head(wheel: TrainWheels, extra: float, is_forward: bool) -> void:
	wheel_reached_head.emit(wheel, extra, is_forward)

# The wheel has reached the tail
func on_wheel_reached_tail(wheel: TrainWheels, extra: float, is_forward: bool) -> void:
	wheel_reached_tail.emit(wheel, extra, is_forward)


func _update_end_points() -> void:
	curve_points = curve.get_baked_points()
	_update_multimesh()
	tail.progress_ratio = 1.0
	head.progress_ratio = 0.0


func _update_multimesh() -> void:
	if !multi_mesh:
		return

	var crossties: MultiMesh = multi_mesh.multimesh
	crossties.mesh = track_mesh

	var curve_length: float = curve.get_baked_length()
	var crosstie_count: int = round(curve_length / crosstie_distance)
	crossties.instance_count = crosstie_count

	for i: int in range(crosstie_count):
		var t: Transform3D = Transform3D()
		var crosstie_position: Vector3 = curve.sample_baked(
			(i * crosstie_distance) + crosstie_distance / 2.0)
		var next_position: Vector3 =  curve.sample_baked((i + 1) * crosstie_distance)
		t.origin = crosstie_position
		t = t.looking_at(next_position, Vector3.UP, true)
		crossties.set_instance_transform(i, t)
