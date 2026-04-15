@tool
extends J_Gizmo
class_name J_Gizmo2D


@export var usereferenceRotation : bool = true :
    set(inp):
        usereferenceRotation = inp
        on_var_changed()

@export var offset : float = 14.0 : 
    set(inp):
        offset = inp
        on_var_changed()

@export var gizmoOffsetVector : Vector2 = Vector2.ZERO :
    set(inp):
        gizmoOffsetVector = inp
        on_var_changed()


#region Position Calculations
# Note: These functions convert between the gizmo's local position ( position ) and its position on the viewport, 
# taking into account the gizmo's owner's position and rotation, as well as the viewport's zoom and offset. 
# The get_display_position_from_position function converts a local position to a viewport position for drawing the gizmo,
# while the get_position_from_viewport_position function converts a viewport position (such as from mouse input) back to a 
# local position for use in the gizmo's drag functions.
func get_display_position_from_position( givenPosition : Vector2 ) -> Vector2:
    var refPosRot : Array = get_ref_pos_and_rot()

    if refPosRot.is_empty():
        return( Vector2.ZERO )
    
    var calculatedPosition : Vector2 = refPosRot[POS_INDEX]

    if usereferenceRotation:
        calculatedPosition += (givenPosition.rotated(refPosRot[ROT_INDEX]))
    else:
        calculatedPosition += givenPosition


    # Scale and offset the viewport position of the gizmo based on viewport's position and zoom.
    var viewportTransform : Transform2D = get_viewport_transform()
    calculatedPosition *= viewportTransform.x.x
    calculatedPosition += viewportTransform.origin

    calculatedPosition += offset * gizmoOffsetVector.rotated( refPosRot[ROT_INDEX] )

    return( calculatedPosition )

# todo - check double check the rotation functionality.
func get_position_from_viewport_position( viewportPosition : Vector2 ) -> Vector2:
    var refPosRot : Array = get_ref_pos_and_rot()

    if refPosRot.is_empty():
        return( Vector2.ZERO )


    var calculatedPosition : Vector2 = viewportPosition - offset * gizmoOffsetVector.rotated( refPosRot[ROT_INDEX] )

    # Remove the viewport's scale and offset from the position
    var viewportTransform : Transform2D = get_viewport_transform()
    calculatedPosition -= viewportTransform.origin
    calculatedPosition /= viewportTransform.x.x

    calculatedPosition -= refPosRot[POS_INDEX]

    if usereferenceRotation:
        calculatedPosition = calculatedPosition.rotated( -refPosRot[ROT_INDEX] )
    else:
        calculatedPosition -= viewportPosition

    return( calculatedPosition )


const POS_INDEX : int = 0
const ROT_INDEX : int = 1
## Gets the global position and rotation of the gizmo's owner.[br]
## Format : [ global_position, global_rotation ] | Shorthands : OWNER_POS_INDEX, OWNER_ROT_INDEX [br]
## Returns an empty array if the owner is not of type Node2D or Control, and prints an error to the console.
func get_ref_pos_and_rot() -> Array:
    var positionalNode : Node

    if referenceNode != null:
        if referenceNode is CanvasItem:
            positionalNode = referenceNode
        else:
            printerr( "Positional reference node for J_Gizmo2D is not a CanvasItem. Using owner as reference node." )
            positionalNode = owner
    else:
        positionalNode = owner
    

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



#region Utils
func get_viewport_transform() -> Transform2D:
    return( EditorInterface.get_editor_viewport_2d().get_final_transform() )
