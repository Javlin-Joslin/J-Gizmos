@tool
extends J_Gizmo
class_name J_Gizmo2D


@export var useReferenceRotation : bool = true :
    set(inp):
        useReferenceRotation = inp
        on_var_changed()


func position_canvas() -> void:
    var refPosRot : Array = get_ref_pos_and_rot()
    canvas.position = refPosRot[POS_INDEX]
    if useReferenceRotation:
        canvas.rotation = refPosRot[ROT_INDEX]
    else:
        canvas.rotation = 0.0

#region Position Calculations



const POS_INDEX : int = 0
const ROT_INDEX : int = 1
## Gets the global position and rotation of the gizmo's owner.[br]
## Format : [ global_position, global_rotation ] | Shorthands : OWNER_POS_INDEX, OWNER_ROT_INDEX [br]
## Returns an empty array if the owner is not of type Node2D or Control, and prints an error to the console.
func get_ref_pos_and_rot() -> Array:
    var positionalNode : Node = get_ref_node()

    if positionalNode is Node2D:
        return([
            positionalNode.get_viewport_transform() * positionalNode.global_position,
            positionalNode.global_rotation
        ])
    
    elif positionalNode is Control:
        return([
            positionalNode.get_global_position(),
            positionalNode.get_global_transform().get_rotation()
        ])
    
    else:
        printerr( "J_Gizmo2D attempted to use owner as positional reference node but it is not a CanvasItem." )
        return( [] )

## The owner can only be returned as the reference node if it is a CanvasItem, otherwise an error is printed and null is returned.
func get_ref_node() -> Node:
    if referenceNode != null:
        if referenceNode is CanvasItem:
            return( referenceNode )
        else:
            printerr( "Positional reference node for J_Gizmo2D is not a CanvasItem. Using owner as reference node." )
            return( owner )
    else:
        return( owner )

#region Utils
## Helper function to get the final transform of the viewport the gizmo is being drawn on. Used for various calculations, such as getting the mouse position in relation to the gizmo.
func get_viewport_transform() -> Transform2D:
    return( EditorInterface.get_editor_viewport_2d().get_final_transform() )
