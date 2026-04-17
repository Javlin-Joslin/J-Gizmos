extends Node2D
class_name Gizmo_Canvas

var ownerGizmo : J_Gizmo = null
var refNode : Node = null

func _ready():
    pass

func _draw() -> void:
    if ownerGizmo != null:
        ownerGizmo.position_canvas()
        ownerGizmo.draw_gizmo()