extends Resource
## A helper Class that can be used as a lightweight and positional, rotational, and scale reference for 
## J_Gizmo2Ds when you don't want to use a CanvasItem.
class_name Gizmo2D_RefNode

signal position_changed( new_position : Vector2, old_position : Vector2 )
var position : Vector2 = Vector2.ZERO : 
	set(inp):
		var oldPos : Vector2 = position
		position = inp
		position_changed.emit( position, oldPos )

signal rotation_changed( new_rotation : float, old_rotation : float )
var rotation : float = 0.0 :
	set(inp):
		var old_rotation : float = rotation
		rotation = inp
		rotation_changed.emit( rotation, old_rotation )

signal scale_changed( new_scale : Vector2, old_scale : Vector2 )
var scale : Vector2 = Vector2.ONE :
	set(inp):
		var old_scale : Vector2 = scale
		scale = inp
		scale_changed.emit( scale, old_scale )