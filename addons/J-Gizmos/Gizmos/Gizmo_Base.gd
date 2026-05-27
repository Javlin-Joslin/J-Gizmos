@tool
extends Resource
## Base class of all gizmos in the J-Gizmo plugin. Not meant to be instantiated directly.
class_name J_Gizmo

#region Plugin Variables
## Reference to the J-Gizmo plugin's EditorPlugin node. Set automatically by the plugin.
var plugin : EditorPlugin
## Emitted when the gizmo's canvas is changed
signal canvas_changed( canvas: Gizmo_Canvas )
## What the gizmos are drawn on in the viewport. Set automatically by the plugin.
var canvas : Gizmo_Canvas = null :
    set(inp):
        canvas = inp
        canvas_changed.emit( inp )

## Used by the gizmo's canvas to position itself based on the gizmo's position calculations. Automatically called by the plugin.
func position_canvas() -> void:
    canvas.position = Vector2.ZERO
    canvas.rotation = 0.0
    canvas.scale = Vector2.ONE

## Emitted when the gizmo's owner variable is changed.
signal owner_changed( newOwner : Object)
## Reference to the object that the gizmo get's all that contain's all the Undo Redo functions and also used as the reference node 
## if referenceNode is not set and the owner is a CanvasItem. Set automatically by the plugin.
var owner = null :
    set(inp):
        owner = inp
        owner_changed.emit( owner )
## Emitted when the gizmo's owner variable is changed.
signal referenceNode_changed( newReferenceNode : Node )
## An Optional variable that, when set, makes the gizmo use the position and rotation of the given node as a reference instead of the 
## owner. If the this variable is unset and the owner is a CanvasItem, the gizmo will use the owner as the reference node.
var referenceNode : Object = null :
    set(inp):
        if inp == null or inp is Node or inp is Gizmo2D_RefNode:
            referenceNode = inp
        else:
            printerr( "Reference node for gizmo be a Node, Gizmo2D_RefNode, or null." )
            referenceNode = null
        referenceNode_changed.emit( referenceNode )
        on_var_changed()


## What the canvas calls to draw the gizmo.
func draw_gizmo() -> void:
    pass


#region Undo Redo
## The name of this gizmo's action for the editor's undo/redo stack.
@export var actionName : String = "Used Gizmo" :
    set(inp):
        actionName = inp
        on_var_changed()

@export_subgroup( "UndoRedo Callbacks" )
## [color=red]-Required-[/color] Name of the method called from the owner node when attempting to undo or cancel the gizmo's action. This may seem like a weird way to do this but I believe it's the way that plays best with the Godot editor's undo/redo system.[br]
## Signature: [code]func example_function( argsDict : Dictionary ): -> void[/code][br]
## The structure of the Dictionary passed to the undo function will vary based on the gizmo and will be noted in their class description.
@export var onUndo : String = ''
## [color=red]-Required-[/color] Name of the method called from the owner node when attempting to redo the gizmo's action. This may seem like a weird way to do this but I believe it's the way that plays best with the Godot editor's undo/redo system.[br]
## Signature: [code]func example_function( argsDict : Dictionary ): -> void[/code][br]
## The structure of the Dictionary passed to the redo function will vary based on the gizmo and will be noted in their class description.
@export var onRedo : String = ''
## [color=purple]-Advanced-[/color] If defined, the method with this name will completely override the default undo/redo system of the plugin for the gizmo.[br]
## Signature: [code]func example_function(): -> void[/code]
@export var overrideUndoRedo : String = ''

## sets up the undo redo actions for the gizmo.
func _setup_undo_redo( redoArgs : Dictionary, undoArgs : Dictionary, actionName : String = 'Gizmo Action' ) -> bool:
    if not _try_using( overrideUndoRedo ):
        if _owner_method_exists( onUndo ) and _owner_method_exists( onRedo ):
            var undoRedoManager : EditorUndoRedoManager = plugin.get_undo_redo()
            undoRedoManager.create_action( actionName )

            undoRedoManager.add_undo_method( owner, onUndo, undoArgs )
            undoRedoManager.add_undo_method( plugin, 'queue_refresh' )
            undoRedoManager.add_do_method( owner, onRedo, redoArgs )
            undoRedoManager.add_do_method( plugin, 'queue_refresh' )

            undoRedoManager.commit_action( false )
            return( true )
        
        if owner.get('name') != null:
            printerr( 'Warning: No valid undo/redo functions defined for gizmo in ' , owner.name,'.' )
        else:
            printerr( 'Warning: No valid undo/redo functions defined for gizmo.' )
        

    return( false )

#endregion


## Line saver that keeps you from having to write emit_changed() and refresh_canvas() on every variable setter that changes the gizmo's appearance/position.
func on_var_changed() -> void:
    emit_changed()
    refresh_canvas()


#region Forwarded Functions
## Handles input events forwarded from the plugin. This function controls the interaction of the gizmo with mouse events in the viewport.
func _on_canvas_gui_input( event ) -> bool:
    if plugin == null:
        plugin = J_Gizmo_Master.get_master()
    return( false )

## Handles drawing the gizmo on the viewport. This function is called from the plugin and controls how the gizmo is drawn.
func _on_canvas_draw_over_viewport( viewport_control ) -> void:
    canvas.queue_redraw()

#endregion


#region Utils

## Helper to setup the gizmo as a subgizmo, automatically setting the owner, canvas, and reference node based on the given owner gizmo. Also connects the owner's canvas_changed signal to update the subgizmo's canvas whenever the owner's canvas changes.
func setup_as_subgizmo( ownerGizmo : J_Gizmo ) -> void:
    owner = ownerGizmo
    owner.canvas_changed.connect( _set_canvas )
    canvas = ownerGizmo.canvas
    referenceNode = ownerGizmo.get_ref_node()
    owner.owner_changed.connect( update_subgizmo_reference_node.unbind(1) )
    owner.referenceNode_changed.connect( update_subgizmo_reference_node.unbind(1) )


func update_subgizmo_reference_node() -> void:
    referenceNode = owner.get_ref_node()

## As the name suggests.
func _set_canvas( newCanvas : Gizmo_Canvas ) -> void:
    canvas = newCanvas

## Helper function that attempts to call a function with the given name from the owner node. Used to simplify calling the various named functions without needing to manually write checkers every time.
func _try_using(func_name : String, args : Array = [] ) -> bool:
    if _owner_method_exists( func_name ):
        owner.callv( func_name, args )
        return( true )
    
    return( false )

## Helper function that checks if the owner node has a method with the given name.
func _owner_method_exists( func_name : String ) -> bool:
    if func_name != '':
        if owner.has_method( func_name ):
            return( true )
        
        printerr( 'Gizmo owner does not have a method named: ' + func_name )
        return( false )
    
    return( false )

## Helper function to that checks if the reference node is set, and if not, returns the owner to be used as the reference node.
func get_ref_node() -> Object:
    if referenceNode == null:
        return( owner )
    
    return( referenceNode )

## Refreshes the gizmo's canvas.
func refresh_canvas():
    if canvas != null:
        canvas.queue_redraw()

## Gets the local position of the mouse relative to the gizmo's reference node.
func get_local_mouse_position() -> Vector2:
    if canvas == null:
        return( Vector2.ZERO )
    
    return( canvas.get_local_mouse_position() )

## gets the viewport that the gizmo is being drawn on.
func get_target_viewport() -> Viewport:
    return EditorInterface.get_editor_viewport_2d()


#endregion