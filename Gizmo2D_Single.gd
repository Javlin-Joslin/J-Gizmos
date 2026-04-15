extends J_Gizmo_Single
## Resource class used by the J-Gizmo plugin to draw and calculate the positions of gizmos in 2D space. Pass this resource from a "setup_gizmos" function within a CanvasItem node to draw it.
class_name J_Gizmo_Single2D

## Static Constructor to call in the "setup_gizmos" function. Pass in the "gizmo_master" arguement as the pluginNode. Recommend using the "quick_setup" function after creating the gizmo to set up the undo/redo and onRelease functions.
static func new_gizmo( pluginNode : EditorPlugin, ownerNode : Node ) -> J_Gizmo_Single2D:
    var newGizmo = J_Gizmo_Single2D.new()
    newGizmo.plugin = pluginNode
    newGizmo.owner = ownerNode
    return( newGizmo )

## Dictates whether the gizmo's position is affected by the rotation of its owner. If true, the gizmo's position will be rotated along with its owner. If false, the gizmo's position will not be affected by its owner's rotation.
var useOwnerRotation : bool = true

enum GIZMO_STYLES {
    CIRCLE,
    SQUARE
}
## Dictates the visual style of the gizmo. Options are defined in the GIZMO_STYLES enum.
var gizmoStyle : GIZMO_STYLES = GIZMO_STYLES.CIRCLE

## Direction and magnitude of the gizmo's visual offset from its actual position. The magnitude of the offset is determined by multiplying this vector by the constant OFFSET and can be affected by the rotation of the gizmo's owner if useOwnerRotation is true.
var gizmoOffsetVector : Vector2 = Vector2.ZERO


func _draw_gizmo( viewport_control ) -> void:
    displayPosition = get_display_position_from_position( position )
    match gizmoStyle:
        GIZMO_STYLES.CIRCLE:
            if _mouseInside:
                _draw_circle_gizmo( viewport_control, displayPosition, gizmoSize, max( 0.0, gizmoOutlineActive ), gizmoColor2, gizmoColor1 )
            else:
                _draw_circle_gizmo( viewport_control, displayPosition, gizmoSize, gizmoOutline, gizmoColor2, gizmoColor1 )

        GIZMO_STYLES.SQUARE:
            if _mouseInside:
                _draw_square_gizmo( viewport_control, displayPosition, gizmoSize, max( 0.0, gizmoOutlineActive ), gizmoColor2, gizmoColor1 )
            else:
                _draw_square_gizmo( viewport_control, displayPosition, gizmoSize, gizmoOutline, gizmoColor2, gizmoColor1 )


#region Position Calculations
# Note: These functions convert between the gizmo's local position ( position ) and its position on the viewport, 
# taking into account the gizmo's owner's position and rotation, as well as the viewport's zoom and offset. 
# The get_display_position_from_position function converts a local position to a viewport position for drawing the gizmo,
# while the get_position_from_viewport_position function converts a viewport position (such as from mouse input) back to a 
# local position for use in the gizmo's drag functions.
func get_display_position_from_position( givenPosition : Vector2 ) -> Vector2:
    var calculatedPosition : Vector2
    var ownerPosRot : Array = get_owner_pos_and_rot()
    var ownerRotation : float = 0.0

    if ownerPosRot.is_empty():
        return( Vector2.ZERO )
    
    calculatedPosition = ownerPosRot[0]
    ownerRotation = ownerPosRot[1]

    if useOwnerRotation:
        calculatedPosition += (givenPosition.rotated(ownerRotation))

    else:
        calculatedPosition += givenPosition


    # Scale and offset the viewport position of the gizmo based on viewport's position and zoom.
    var viewportTransform : Transform2D = get_viewport_transform()
    calculatedPosition *= viewportTransform.x.x
    calculatedPosition += viewportTransform.origin

    calculatedPosition += OFFSET * gizmoOffsetVector.rotated( ownerRotation )

    return( calculatedPosition )

# todo - check double check the rotation functionality.
func get_position_from_viewport_position( viewportPosition : Vector2 ) -> Vector2:
    var calculatedPosition : Vector2
    var ownerPosRot : Array = get_owner_pos_and_rot()
    var ownerRotation : float = 0.0

    if ownerPosRot.is_empty():
        return( Vector2.ZERO )

    var ownerPos : Vector2 = ownerPosRot[ OWNER_POS_INDEX ]
    ownerRotation = ownerPosRot[ OWNER_ROT_INDEX ]

    calculatedPosition = viewportPosition - OFFSET * gizmoOffsetVector.rotated( ownerRotation )

    # Remove the viewport's scale and offset from the position
    var viewportTransform : Transform2D = get_viewport_transform()
    calculatedPosition -= viewportTransform.origin
    calculatedPosition /= viewportTransform.x.x

    calculatedPosition -= ownerPos

    if useOwnerRotation:
        calculatedPosition = calculatedPosition.rotated( -ownerRotation )

    return( calculatedPosition )


const OWNER_POS_INDEX : int = 0
const OWNER_ROT_INDEX : int = 1
## Gets the global position and rotation of the gizmo's owner.[br]
## Format : [ global_position, global_rotation ] | Shorthands : OWNER_POS_INDEX, OWNER_ROT_INDEX [br]
## Returns an empty array if the owner is not of type Node2D or Control, and prints an error to the console.
func get_owner_pos_and_rot() -> Array:
    if owner is Node2D:
        return([
            owner.get_viewport_transform() * owner.global_position,
            owner.global_rotation
        ])
    elif owner is Control:
        return([
            owner.get_global_position(),
            owner.get_global_transform().get_rotation()
        ])
    else:
        printerr(  'JGizmo_2D only supports owners of type Node2D or Control.' )
        return( [] )
