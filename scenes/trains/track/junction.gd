class_name TrainTrackJunction
extends Area3D

@export var track: TrainTrack
@export var side: TrainTrack.Sides
@export var enabled: bool = true:
	set(value):
		enabled = value
		set_deferred(&"monitoring", value)
		set_deferred(&"monitorable", value)


func _ready() -> void:
	area_entered.connect(_on_junction_area_entered)


func _on_junction_area_entered(area: TrainTrackJunction) -> void:
	if !enabled || !area.enabled:
		return
	track.link_track(area.track, side, area.side)
	area.track.link_track(track, area.side, side)
	enabled = false
	area.enabled = false
