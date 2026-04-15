@tool
extends J_Gizmo2D
class_name J_Gizmo2D_Handle

#region Visual Variables
enum HANDLE_VISUAL {
    CIRCLE,
    SQUARE,
    CUSTOM
}
## Dictates the visual style of the gizmo. Options are defined in the HANDLE_VISUAL enum.
@export var handleVisual : HANDLE_VISUAL = HANDLE_VISUAL.CIRCLE :
    set(inp):
        handleVisual = inp
        on_var_changed()

## Position of the gizmo in the owner node's local space. Set this to move the gizmo.
@export var position : Vector2 = Vector2.ZERO :
    set(inp):
        position = inp
        on_var_changed()
## Dictates whether the gizmo's position is affected by the rotation of its owner. If true, the gizmo's position will be rotated along with its owner. If false, the gizmo's position will not be affected by its owner's rotation.
@export var useOwnerRotation : bool = true :
    set(inp):
        useOwnerRotation = inp
        on_var_changed()
## Gizmo's position in the viewport, calculated from the owner's position and the viewport's transform. Updated automatically.
var _displayPosition : Vector2 = Vector2.ZERO
## Used to store the gizmo's position when it is grabbed, for use in undo/redo operations. Updated automatically.
var _oldPosition : Vector2 = Vector2.ZERO

@export var gizmoSize : float = 5.0 :
    set(inp):
        gizmoSize = inp
        on_var_changed()
@export var gizmoOutline : float = 1.0 :
    set(inp):
        gizmoOutline = inp
        on_var_changed()
@export var gizmoOutlineActive : float = 3.0 :
    set(inp):
        gizmoOutlineActive = inp
        on_var_changed()

@export var gizmoColor1 : Color = Color.HOT_PINK :
    set(inp):
        gizmoColor1 = inp
        on_var_changed()
@export var gizmoColor2 : Color = Color.PINK :
    set(inp):
        gizmoColor2 = inp
        on_var_changed()


var mouseInside : bool = false
## States enum for the gizmo's input handling. The state controls how the gizmo reacts to different input events.
enum STATES {
    DEFAULT,
    GRABBED
}
## The current state of the gizmo. Set automatically by the input handling function.
var _state : STATES = STATES.DEFAULT

#endregion

## Name of the action for this gizmo's undo/redo operations in the editor's undo/redo stack.
@export var actionName : String = "Move Handle" :
    set(inp):
        actionName = inp
        on_var_changed()


#region Callback Function Names
@export_group( "Callbacks" )
## [color=orange]-Optional-[/color] If defined, the method with this name will be called from the owner node when the gizmo is initially grabbed (left-clicked).[br]
## Signature: [code]func example_function( gizmo : JGizmo ): -> void[/code]
@export var onGrab : String = '' :
    set(inp):
        onGrab = inp
        on_var_changed()
## [color=orange]-Optional-[/color] If defined, the method with this name will be called from the owner node when the gizmo is released (after being dragged).[br]
## Signature: [code]func example_function( gizmo : JGizmo ): -> void[/code]
@export var onRelease : String = '' :
    set(inp):
        onRelease = inp
        on_var_changed()
## [color=red]-Required-[/color] Name of the method called from the owner node when the gizmo is dragged.[br]
## Signature: [code]func example_function( dragPos : Vector2,  gizmo : JGizmo ): -> void[/code]
@export var onDrag : String = '' :
    set(inp):
        onDrag = inp
        on_var_changed()

@export_subgroup( "Hover Callbacks" )
## [color=orange]-Optional-[/color] If defined, the method with this name will be called from the owner node when the mouse starts hovering over the gizmo.[br]
## Signature: [code]func example_function( gizmo : JGizmo ): -> void[/code]
@export var onHover : String = '' :
    set(inp):
        onHover = inp
        on_var_changed()
## [color=orange]-Optional-[/color] If defined, the method with this name will be called from the owner node when the mouse stops hovering over the gizmo.[br]
## Signature: [code]func example_function( gizmo : JGizmo ): -> void[/code]
@export var onUnhover : String = '' :
    set(inp):
        onUnhover = inp
        on_var_changed()

@export_subgroup( "Undo/Redo Callbacks" )
## [color=red]-Required-[/color] Name of the method called from the owner node when attempting to undo or cancel the gizmo's action.[br]
## Signature: [code]func example_function( oldPosition : Vector2, newPosition : Vector2 ): -> void[/code]
@export var onUndo : String = '' :
    set(inp):
        onUndo = inp
        on_var_changed()
## [color=red]-Required-[/color] Name of the method called from the owner node when attempting to redo the gizmo's action.[br]
## Signature: [code]func example_function( oldPosition : Vector2, newPosition : Vector2 ): -> void[/code]
@export var onRedo : String = '' :
    set(inp):
        onRedo = inp
        on_var_changed()
## [color=purple]-Advanced-[/color] If defined, the method with this name will completely override the default undo/redo system of the plugin for the gizmo.[br]
## Signature: [code]func example_function( gizmo : JGizmo ): -> void[/code]
@export var overrideUndoRedo : String = '' :
    set(inp):
        overrideUndoRedo = inp
        on_var_changed()
## [color=orange]-Optional-[/color] If defined, the method with this name will override the default cancel action of the gizmo ( onUndo ).[br]
## Signature: [code]func example_function( gizmo : JGizmo ): -> void[/code]
@export var overrideCancel : String = '' :
    set(inp):
        overrideCancel = inp
        on_var_changed()

@export_subgroup( "Custom Draw Callbacks" )
## [color=purple]-Advanced-[/color] While the "handle" variable is set to "CUSTOM" the method named will be called from the owner.[br]
## Signature: [code]func example_function( viewportControl : Control, gizmo : JGizmo ): -> void[/code]
@export var customDraw : String = '' :
    set(inp):
        customDraw = inp
        on_var_changed()
## [color=orange]-Optional-[/color] If defined, the method with this name will be called from the owner node at the end of the gizmo's draw function (after the gizmo is drawn).[br]
## Signature: [code]func example_function( viewportControl : Control, gizmo : JGizmo ): -> void[/code]
@export var postDraw : String = '' :
    set(inp):
        postDraw = inp
        on_var_changed()

#endregion

#region Quick Setup
## Sets the required function names for the gizmo's drag, undo, and redo actions. Used to simplify setting up the gizmo after creating it.
func quick_setup( dragFunc : String, undoFunc : String, redoFunc : String, givenActionName : String = 'Gizmo Action' ) -> void:
    onDrag = dragFunc
    onUndo = undoFunc
    onRedo = redoFunc
    actionName = givenActionName

#endregion

#region Input
func _on_canvas_gui_input(event) -> bool:
    match _state:
        STATES.DEFAULT:
            if event is InputEventMouseMotion:
                if event.position.distance_to( _displayPosition ) < gizmoSize:
                    if mouseInside == false:
                        _try_using( onHover )
                        mouseInside = true
                        queue_refresh()
                    
                    return( true )
                elif mouseInside:
                    _try_using( onUnhover )
                    mouseInside = false
                    queue_refresh()

            
            elif event is InputEventMouseButton:
                if mouseInside and event.button_index == MouseButton.MOUSE_BUTTON_LEFT and event.pressed:
                    _oldPosition = position
                    plugin.grabbedGizmo = self
                    _update_state( STATES.GRABBED, onGrab )
                    return( true )
        
        STATES.GRABBED:
            mouseInside = true
            if event is InputEventMouseMotion:
                if not _try_using( onDrag, [ get_position_from_viewport_position( event.position ), self ] ):
                    printerr( 'Warning: No onDrag function defined for gizmo in ' , owner.name,'.' )
                    return( true )

                queue_refresh()
                return( true )
            
            elif event is InputEventMouseButton:
                match event.button_index:
                    # Cancel the drag with a right-click, which will call the undo function and return the gizmo to its original position.
                    MouseButton.MOUSE_BUTTON_RIGHT when event.pressed == true:
                        plugin.grabbedGizmo = null
                        if not _try_using( overrideCancel ):
                            if _try_using( onUndo, [ _oldPosition, position ] ):
                                printerr( 'Warning: No undo function defined for gizmo in ' , owner.name,'.' )
                                return( true )
                            
                            plugin._handles( owner )
                        
                        _update_state( STATES.DEFAULT, onRelease )
                        return( true )
                    
                    # Finalize the drag when left click is released, which will call the onRelease function and set up the undo/redo actions in the editor's undo/redo stack.
                    MouseButton.MOUSE_BUTTON_LEFT when event.pressed == false:
                        _update_state( STATES.DEFAULT, onRelease )
                        plugin.grabbedGizmo = null
                        if not _try_using( overrideUndoRedo ):
                            if _owner_method_exists( onUndo ) and _owner_method_exists( onRedo ):
                                var undoRedoManager : EditorUndoRedoManager = plugin.get_undo_redo()
                                undoRedoManager.create_action( actionName )

                                undoRedoManager.add_undo_method( owner, onUndo,  _oldPosition, position )
                                undoRedoManager.add_undo_method( plugin, '_handles', owner )
                                undoRedoManager.add_do_method( owner, onRedo,  _oldPosition, position )
                                undoRedoManager.add_do_method( plugin, '_handles', owner )

                                undoRedoManager.commit_action()
                                return( true )

                            printerr( 'Warning: No undo/redo functions defined for gizmo in ' , owner.name,'.' )
                        

                        return( true )
    
    return( false )

#endregion

#region Drawing
func _on_canvas_draw_over_viewport( viewport_control ) -> void:
    _displayPosition = get_display_position_from_position( position )

    match handleVisual:
        HANDLE_VISUAL.CIRCLE:
            viewport_control.draw_circle( _displayPosition, gizmoSize, gizmoColor1 )
            if mouseInside:
                _draw_circle_gizmo( viewport_control, _displayPosition, gizmoSize, max( 0.0, gizmoOutlineActive ), gizmoColor2, gizmoColor1 )
            else:
                _draw_circle_gizmo( viewport_control, _displayPosition, gizmoSize, gizmoOutline, gizmoColor2, gizmoColor1 )

        HANDLE_VISUAL.SQUARE:
            if mouseInside:
                _draw_square_gizmo( viewport_control, _displayPosition, gizmoSize, max( 0.0, gizmoOutlineActive ), gizmoColor2, gizmoColor1 )
            else:
                _draw_square_gizmo( viewport_control, _displayPosition, gizmoSize, gizmoOutline, gizmoColor2, gizmoColor1 )
            
        HANDLE_VISUAL.CUSTOM:
            if not _try_using( customDraw, [ viewport_control, self ] ):
                printerr( 'Warning: Gizmo in ' , owner.name, ' is set to CUSTOM style but has no customDraw function defined.' )
    
    _try_using( postDraw, [ viewport_control, self ] )

## Helper function to draw a simple circle gizmo. Used automatically depending on gizmoStyle.
func _draw_circle_gizmo( 
        viewportControl : Control, gizmodisplayPosition : Vector2, 
        size : float = 4.0, outlineSize : float = 2.0, 
        outlineColor : Color = Color.WHITE_SMOKE, fillColor : Color = Color.HOT_PINK 
    ) -> void:
    viewportControl.draw_circle( gizmodisplayPosition, size, outlineColor)
    viewportControl.draw_circle( gizmodisplayPosition, size-outlineSize, fillColor )

## Helper function to draw a simple square gizmo. Used automatically depending on gizmoStyle.
func _draw_square_gizmo( 
        viewportControl : Control, gizmodisplayPosition : Vector2, 
        size : float = 4.0, outlineSize : float = 2.0, 
        outlineColor : Color = Color.WHITE_SMOKE, fillColor : Color = Color.HOT_PINK 
    ) -> void:
    viewportControl.draw_rect(
        Rect2(gizmodisplayPosition - Vector2(size, size), Vector2(size, size)*2.0),
        outlineColor,
        true
    )
    viewportControl.draw_rect(
        Rect2(gizmodisplayPosition - Vector2(size-outlineSize, size-outlineSize), Vector2((size-outlineSize)*2.0, (size-outlineSize)*2.0)),
        fillColor,
        true
    )

#endregion


#region Utils
## Helper function to update the state of the gizmo and call the appropriate functions when the state changes.
func _update_state( newState : STATES, triggeredFunc : String ) -> void:
    _state = newState
    queue_refresh()
    _try_using( triggeredFunc )