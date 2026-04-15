@tool
extends J_Gizmo2D

## Todo : add class docu comment
class_name J_Gizmo_Single

## Position of the gizmo in the owner node's local space. Set this to move the gizmo.
var position : Vector2 = Vector2.ZERO
## Gizmo's position in the viewport, calculated from the owner's position and the viewport's transform. Updated automatically.
var displayPosition : Vector2 = Vector2.ZERO
## Used to store the gizmo's position when it is grabbed, for use in undo/redo operations. Updated automatically.
var _oldPosition : Vector2 = Vector2.ZERO

var gizmoSize : float = 5.0
var gizmoOutline : float = 1.0
var gizmoOutlineActive : float = 3.0
## Inner color of gizmo.
var gizmoColor1 : Color = Color.HOT_PINK
## Outer color of gizmo.
var gizmoColor2 : Color = Color.WHITE_SMOKE
## Name of the action for this gizmo's undo/redo operations in the editor's undo/redo stack.
var actionName : String = 'Gizmo Action'

## Simple bool that represents if the mouse is currently hovering over the gizmo or not. Set automatically.
var _mouseInside : bool = false
## States enum for the gizmo's input handling. The state controls how the gizmo reacts to different input events.
enum STATES {
    DEFAULT,
    GRABBED
}
## The current state of the gizmo. Set automatically by the input handling function.
var _state : STATES = STATES.DEFAULT

## [color=orange]-Optional-[/color] If defined, the method with this name will be called from the owner node when the gizmo is initially grabbed (left-clicked).[br]
## Signature: [code]func example_function( gizmo : JGizmo ): -> void[/code]
var onGrab : String = ''
## [color=orange]-Optional-[/color] If defined, the method with this name will be called from the owner node when the gizmo is released (after being dragged).[br]
## Signature: [code]func example_function( gizmo : JGizmo ): -> void[/code]
var onRelease : String = ''
## [color=red]-Required-[/color] Name of the method called from the owner node when the gizmo is dragged.[br]
## Signature: [code]func example_function( dragPos : Vector2,  gizmo : JGizmo ): -> void[/code]
var onDrag : String = ''
## [color=orange]-Optional-[/color] If defined, the method with this name will override the default cancel action of the gizmo ( onUndo ).[br]
## Signature: [code]func example_function( gizmo : JGizmo ): -> void[/code]
var overrideCancel : String = ''
## [color=red]-Required-[/color] Name of the method called from the owner node when attempting to undo or cancel the gizmo's action.[br]
## Signature: [code]func example_function( oldPosition : Vector2, newPosition : Vector2 ): -> void[/code]
var onUndo : String = ''
## [color=red]-Required-[/color] Name of the method called from the owner node when attempting to redo the gizmo's action.[br]
## Signature: [code]func example_function( oldPosition : Vector2, newPosition : Vector2 ): -> void[/code]
var onRedo : String = ''
## [color=purple]-Advanced-[/color] If defined, the method with this name will override the default undo/redo system.[br]
## Signature: [code]func example_function( gizmo : JGizmo ): -> void[/code]
var overrideUndoRedo : String = ''

## [color=orange]-Optional-[/color] If defined, the method with this name will be called from the owner node when the mouse starts hovering over the gizmo.[br]
## Signature: [code]func example_function( gizmo : JGizmo ): -> void[/code]
var onHover : String = ''
## [color=orange]-Optional-[/color] If defined, the method with this name will be called from the owner node when the mouse stops hovering over the gizmo.[br]
## Signature: [code]func example_function( gizmo : JGizmo ): -> void[/code]
var onUnhover : String = ''

## [color=purple]-Advanced-[/color] If defined, the method with this name will override the default gizmo drawing function.[br]
## Signature: [code]func example_function( viewportControl : Control, gizmo : JGizmo ): -> void[/code]
var overrideDraw : String = ''
## [color=orange]-Optional-[/color] If defined, the method with this name will be called from the owner node at the end of the gizmo's draw function (after the gizmo is drawn).[br]
## Signature: [code]func example_function( viewportControl : Control, gizmo : JGizmo ): -> void[/code]
var postDraw : String = ''

## Sets the required function names for the gizmo's drag, undo, and redo actions. Used to simplify setting up the gizmo after creating it.
func quick_setup( dragFunc : String, undoFunc : String, redoFunc : String, givenName : String = 'Gizmo Action' ) -> void:
    onDrag = dragFunc
    onUndo = undoFunc
    onRedo = redoFunc
    actionName = givenName

#region Input
func _on_canvas_gui_input(event) -> bool:
    match _state:
        STATES.DEFAULT:
            if event is InputEventMouseMotion:
                if event.position.distance_to( displayPosition ) < gizmoSize:
                    if _mouseInside == false:
                        _try_using( onHover )
                        _mouseInside = true
                        queue_refresh()
                    
                    return( true )
                elif _mouseInside:
                    _try_using( onUnhover )
                    _mouseInside = false
                    queue_refresh()

            
            elif event is InputEventMouseButton:
                if _mouseInside and event.button_index == MouseButton.MOUSE_BUTTON_LEFT and event.pressed:
                    _oldPosition = position
                    plugin.grabbedGizmo = self
                    _update_state( STATES.GRABBED, onGrab )
                    return( true )
        
        STATES.GRABBED:
            _mouseInside = true
            if event is InputEventMouseMotion:
                if onDrag == '':
                    printerr( 'Warning: No onDrag function defined for gizmo in ' , owner.name,'.' )
                    return( true )

                owner.call( onDrag, get_position_from_viewport_position( event.position ), self )
                
                queue_refresh()
                return( true )
            
            elif event is InputEventMouseButton:
                match event.button_index:
                    # Cancel the drag with a right-click, which will call the undo function and return the gizmo to its original position.
                    MouseButton.MOUSE_BUTTON_RIGHT when event.pressed == true:
                        plugin.grabbedGizmo = null
                        if not _try_using( overrideCancel ):
                            if onUndo == '':
                                printerr( 'Warning: No undo function defined for gizmo in ' , owner.name,'.' )
                                return( true )
                            owner.call( onUndo, _oldPosition, position )
                            plugin._handles( owner )
                        
                        _update_state( STATES.DEFAULT, onRelease )
                        return( true )
                    
                    # Finalize the drag when left click is released, which will call the onRelease function and set up the undo/redo actions in the editor's undo/redo stack.
                    MouseButton.MOUSE_BUTTON_LEFT when event.pressed == false:
                        _update_state( STATES.DEFAULT, onRelease )
                        plugin.grabbedGizmo = null
                        if not _try_using( overrideUndoRedo ):
                            if onUndo == '' or onRedo == '':
                                printerr( 'Warning: No undo/redo functions defined for gizmo in ' , owner.name,'.' )
                                return( true )
                            var undoRedoManager : EditorUndoRedoManager = plugin.get_undo_redo()
                            undoRedoManager.create_action( actionName )

                            undoRedoManager.add_undo_method( owner, onUndo,  _oldPosition, position )
                            undoRedoManager.add_undo_method( plugin, '_handles', owner )
                            undoRedoManager.add_do_method( owner, onRedo,  _oldPosition, position )
                            undoRedoManager.add_do_method( plugin, '_handles', owner )

                            undoRedoManager.commit_action()
                        

                        return( true )
    
    return( false )

## Helper function that attempts to call a function with the given name from the owner node. Used to simplify calling the various optional functions without needing to check if they exist every time.
func _try_using( func_name : String ) -> bool:
    if func_name != '' and owner.has_method( func_name ):
        owner.call( func_name, self )
        return( true )
        
    return( false )

## Helper function to update the state of the gizmo and call the appropriate functions when the state changes.
func _update_state( newState : STATES, triggeredFunc : String ) -> void:
    _state = newState
    queue_refresh()
    _try_using( triggeredFunc )


#region Drawing
func _on_canvas_draw_over_viewport( viewport_control ) -> void:
    if overrideDraw == '':
        _draw_gizmo( viewport_control )
    elif owner.has_method( overrideDraw ):
        owner.call( overrideDraw, viewport_control, self )
    
    if postDraw != '' and owner.has_method( postDraw ):
        owner.call( postDraw, viewport_control, self )

## Default gizmo drawing function that is overridden by subclasses, called if no overrideDraw function is defined.
func _draw_gizmo( viewport_control ) -> void:
    pass

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


#region Utils
## Gets the transform of the editor viewport.
func get_viewport_transform() -> Transform2D:
    return( EditorInterface.get_editor_viewport_2d().get_final_transform() )

## Refreses the ViewportControl.
func queue_refresh():
    plugin.update_overlays()

## Gets the position in the owner's local space that corresponds to the given viewport position. Overriden by subclasses.
func get_position_from_viewport_position( viewportPosition : Vector2 ) -> Vector2:
    return( viewportPosition )

## Gets the position in the viewport that corresponds to the given position in the owner node's local space. Overriden by subclasses.
func get_display_position_from_position( givenPosition : Vector2 ) -> Vector2:
    return( givenPosition )