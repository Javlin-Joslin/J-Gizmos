extends Node2D
## The canvas that J-Gizmos are drawn on in the viewport. Not meant to be instantiated directly.
class_name Gizmo_Canvas

var ownerGizmo : J_Gizmo = null

func _ready():
    pass

func _draw() -> void:
    if ownerGizmo != null:
        # the positioning and drawing are handeled by the gizmo itself.
        ownerGizmo.position_canvas()
        ownerGizmo.draw_gizmo()