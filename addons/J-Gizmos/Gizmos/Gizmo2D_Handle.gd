@tool
@icon('res://addons/J-Gizmos/Icons/J_Gizmo2D_Handle.svg')
extends J_Gizmo2D
## A simple gizmo that can be positioned around the owner's local space and used as a handle to perform tasks via the gizmo's many [code]Signals[/code] and undo/redo callbacks.[br]
## undo callback arguement Dict: [code]{ oldPosition : Vector2, newPosition : Vector2 }[/code][br]
## redo callback arguement Dict: [code]{ oldPosition : Vector2, newPosition : Vector2 }[/code][br]
class_name J_Gizmo2D_Handle

#region Quick Setup
## Helper function that connects the [code]on_drag[/code] signal to the given function and sets the required function names for the gizmo's undo and redo actions. Used to simplify setting up the gizmo after creating it.[br]
## undo callback arguement Dict: [code]{ oldPosition : Vector2, newPosition : Vector2 }[/code][br]
## redo callback arguement Dict: [code]{ oldPosition : Vector2, newPosition : Vector2 }[/code][br]
func quick_setup( dragFunc : Callable, undoFuncName : String, redoFuncName : String, givenActionName : String = 'Gizmo Action' ) -> void:
    on_drag.connect( dragFunc )
    onUndo = undoFuncName
    onRedo = redoFuncName
    actionName = givenActionName

#endregion

#region Visual Variables
## Handle display options. [br]
## - [code]CIRCLE[/code]: A simple circle. [br]
## - [code]SQUARE[/code]: A simple square. [br]
## - [code]CUSTOM[/code]: Draws nothing, instead emitting the [code]on_custom_draw[/code] signal to allow for completely custom drawing.
enum HANDLE_VISUAL {
    CIRCLE,
    SQUARE,
    CUSTOM
}
## Dictates the visual style of the gizmo.
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
## Gizmo's position as displayed, taking into account the gizmo's offset. Updated automatically.
var _displayPosition : Vector2 = Vector2.ZERO
## Used to store the gizmo's position when it is grabbed, for use in undo/redo operations. Updated automatically.
var _oldPosition : Vector2 = Vector2.ZERO
## Used while dragging the gizmo for calculating the drag vector returned by the on_drag signal. Updated automatically.
var _oldDragPosition : Vector2 = Vector2.ZERO

## The size of the gizmo's handle.
@export var gizmoSize : float = 5.0 :
    set(inp):
        gizmoSize = inp
        on_var_changed()
## Size of the gizmo's outline when the mouse is not hovering over it.
@export var gizmoOutline : float = 1.0 :
    set(inp):
        gizmoOutline = min( inp, gizmoSize )
        on_var_changed()
## Size of the gizmo's outline when the mouse is hovering over it.
@export var gizmoOutlineActive : float = 3.0 :
    set(inp):
        gizmoOutlineActive = min( inp, gizmoSize )
        on_var_changed()
## The gizmo's main (internal) color.
@export var gizmoColor1 : Color = Color.HOT_PINK :
    set(inp):
        gizmoColor1 = inp
        on_var_changed()
## The gizmo's outline (external) color.
@export var gizmoColor2 : Color = Color.PINK :
    set(inp):
        gizmoColor2 = inp
        on_var_changed()
## The distance the gizmo is drawn from it's actual position. The Direction of the offset is determined by [code]gizmoOffsetVector[/code].
@export var offset : float = 14.0 : 
    set(inp):
        offset = inp
        on_var_changed()
## The Vector that determines the direction of the gizmo's offset from its actual position. The magnitude of the offset is determined by [code]offset[/code].
@export var gizmoOffsetVector : Vector2 = Vector2.ZERO :
    set(inp):
        gizmoOffsetVector = inp
        on_var_changed()

## Used to store whether the mouse is currently hovering over the gizmo, for use in drawing and input handling. Updated automatically.
var mouseInside : bool = false
## States enum for the gizmo's input handling. The state controls how the gizmo reacts to different input events.
enum STATES {
    DEFAULT,
    GRABBED
}
## The current state of the gizmo. Set automatically by the input handling function.
var _state : STATES = STATES.DEFAULT

#endregion


#region Signals
## Emitted when the gizmo is grabbed.
signal on_grab( this_gizmo : J_Gizmo2D_Handle )
## Emitted when the gizmo is released after being grabbed.
signal on_release( this_gizmo : J_Gizmo2D_Handle )
## Emitted when the Gizmo is dragged.
signal on_drag( dragPos : Vector2, dragVector : Vector2, this_gizmo : J_Gizmo2D_Handle )
## Emitted when a drag is conceled by right clicking. If nothing is connected to this signal the plugin will run the undo function to return the gizmo to its original position.
signal on_drag_cancel( this_gizmo : J_Gizmo2D_Handle )
## Emitted when the mouse starts hovering over the gizmo.
signal on_hover( this_gizmo : J_Gizmo2D_Handle )
## Emitted when the mouse stops hovering over the gizmo.
signal on_unhover( this_gizmo : J_Gizmo2D_Handle )
## Emitted while the gizmo is in the draw function but before it is actually drawn.
signal pre_draw( gizmo_canvas : Gizmo_Canvas, this_gizmo : J_Gizmo2D_Handle )
## Emitted when the gizmo is drawn while [code]handleVisual[/code] is set to [code]HANDLE_VISUAL.CUSTOM[/code].
signal on_custom_draw( gizmo_canvas : Gizmo_Canvas, this_gizmo : J_Gizmo2D_Handle )

#endregion


#region Input
func _on_canvas_gui_input(event) -> bool:
    super._on_canvas_gui_input(event)
    
    match _state:
        STATES.DEFAULT:
            if event is InputEventMouseMotion:
                var localMousePos : Vector2 = canvas.get_local_mouse_position()
                if localMousePos.distance_to( _displayPosition ) < gizmoSize / get_viewport_transform().x.x:
                    if mouseInside == false:
                        on_hover.emit( self )
                        mouseInside = true
                        refresh_canvas()
                    
                    return( true )
                elif mouseInside:
                    on_unhover.emit( self )
                    mouseInside = false
                    refresh_canvas()

            
            elif event is InputEventMouseButton:
                if mouseInside and event.button_index == MouseButton.MOUSE_BUTTON_LEFT and event.pressed:
                    _oldPosition = position
                    _oldDragPosition = position
                    plugin.grabbedGizmo = self
                    _update_state( STATES.GRABBED, on_grab )
                    return( true )
        
        STATES.GRABBED:
            mouseInside = true
            if event is InputEventMouseMotion:
                var dragPosition : Vector2 = get_local_mouse_position() / get_ref_node().get_global_transform().get_scale()

                on_drag.emit( dragPosition, dragPosition - _oldDragPosition, self )
                _oldDragPosition = dragPosition
                refresh_canvas()
                return( true )
            
            elif event is InputEventMouseButton:
                match event.button_index:
                    # Cancel the drag with a right-click, which will call the undo function and return the gizmo to its original position.
                    MouseButton.MOUSE_BUTTON_RIGHT when event.pressed == true:
                        plugin.grabbedGizmo = null
                        if on_drag_cancel.has_connections():
                            on_drag_cancel.emit( self )
                        else:
                            if not _try_using( onUndo, [ { 'oldPosition' : _oldPosition, 'newPosition' : position } ] ):
                                if owner.get('name') != null:
                                    printerr( 'Warning: No undo function defined for gizmo in ' , owner.name,'.' )
                                else:
                                    printerr( 'Warning: No undo function defined for gizmo.' )

                                return( true )
                            
                            plugin.queue_refresh()
                        
                        _update_state( STATES.DEFAULT )
                        return( true )
                    
                    # Finalize the drag when left click is released, which will call the onRelease function and set up the undo/redo actions in the editor's undo/redo stack.
                    MouseButton.MOUSE_BUTTON_LEFT when event.pressed == false:
                        _update_state( STATES.DEFAULT, on_release )
                        plugin.grabbedGizmo = null
                        _setup_undo_redo( 
                            { 'oldPosition' : _oldPosition, 'newPosition' : position }, 
                            { 'oldPosition' : _oldPosition, 'newPosition' : position }, 
                            actionName 
                        )
                            

                        return( true )
    
    return( false )

#endregion

#region Drawing
func draw_gizmo() -> void:
    var viewportScale : float = get_viewport_transform().x.x
    _displayPosition = position * get_ref_node().get_global_transform().get_scale() + gizmoOffsetVector*offset/viewportScale
    draw_handle( _displayPosition )

## Helper function to draw the gizmo's handle based on the current [code]handleVisual[/code] setting. Called by the main draw function.
func draw_handle( drawPosition : Vector2 ) -> void:
    var viewportScale : float = get_viewport_transform().x.x
    pre_draw.emit( canvas, self )
    match handleVisual:
        HANDLE_VISUAL.CIRCLE:
            # canvas.draw_circle( drawPosition, gizmoSize / viewportScale, gizmoColor1 )
            if mouseInside:
                _draw_circle_gizmo( drawPosition, gizmoSize / viewportScale, max( 0.0, gizmoOutlineActive / viewportScale ), gizmoColor2, gizmoColor1 )
            else:
                _draw_circle_gizmo( drawPosition, gizmoSize / viewportScale, gizmoOutline/viewportScale, gizmoColor2, gizmoColor1 )

        HANDLE_VISUAL.SQUARE:
            if mouseInside:
                _draw_square_gizmo( drawPosition, gizmoSize / viewportScale, max( 0.0, gizmoOutlineActive / viewportScale ), gizmoColor2, gizmoColor1 )
            else:
                _draw_square_gizmo( drawPosition, gizmoSize / viewportScale, gizmoOutline / viewportScale, gizmoColor2, gizmoColor1 )
            
        HANDLE_VISUAL.CUSTOM:
            on_custom_draw.emit( canvas, self )

## Helper function to draw a simple circle gizmo. Used automatically depending on gizmoStyle.
func _draw_circle_gizmo( 
        gizmodisplayPosition : Vector2, 
        size : float = 4.0, outlineSize : float = 2.0, 
        outlineColor : Color = Color.WHITE_SMOKE, fillColor : Color = Color.HOT_PINK 
    ) -> void:
    canvas.draw_circle( gizmodisplayPosition, size, outlineColor)
    canvas.draw_circle( gizmodisplayPosition, size-outlineSize, fillColor )

## Helper function to draw a simple square gizmo. Used automatically depending on gizmoStyle.
func _draw_square_gizmo( 
        gizmodisplayPosition : Vector2, 
        size : float = 4.0, outlineSize : float = 2.0, 
        outlineColor : Color = Color.WHITE_SMOKE, fillColor : Color = Color.HOT_PINK 
    ) -> void:
    canvas.draw_rect(
        Rect2(gizmodisplayPosition - Vector2(size, size), Vector2(size, size)*2.0),
        outlineColor,
        true
    )
    canvas.draw_rect(
        Rect2(gizmodisplayPosition - Vector2(size-outlineSize, size-outlineSize), Vector2((size-outlineSize)*2.0, (size-outlineSize)*2.0)),
        fillColor,
        true
    )

#endregion


#region Utils
## Helper function to update the state of the gizmo and call the appropriate functions when the state changes.
func _update_state( newState : STATES, emit_signal = null) -> void:
    _state = newState
    refresh_canvas()
    if emit_signal is Signal:
        emit_signal.emit( self )

func get_local_mouse_position() -> Vector2:
    var mousePos : Vector2 = super.get_local_mouse_position()

    return( mousePos - (gizmoOffsetVector*offset)/get_viewport_transform().x.x )