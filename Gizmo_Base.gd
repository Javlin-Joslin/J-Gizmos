@tool
extends Resource
## Base class of all gizmos in the J-Gizmo plugin. Not meant to be instantiated directly.
class_name J_Gizmo

## Reference to the J-Gizmo plugin's EditorPlugin node. Set automatically by the plugin.
var plugin : EditorPlugin
## Reference to the node that the gizmo is attached to. Set automatically by the plugin.
var owner = null
## An Optional variable that allows you to easily position the gizmo relative to another node instead of its owner. Typically set automatically but it can be set manually if needed.
var referenceNode : Node = null

#region Forwarded Functions
## Handles input events forwarded from the plugin. This function controls the interaction of the gizmo with mouse events in the viewport.
func _on_canvas_gui_input( event ) -> bool:
    return( false )

## Handles drawing the gizmo on the viewport. This function is called from the plugin and controls how the gizmo is drawn.
func _on_canvas_draw_over_viewport( viewport_control ) -> void:
    pass

#endregion

#region Utils

func on_var_changed() -> void:
    emit_changed()
    queue_refresh()

## Helper function that attempts to call a function with the given name from the owner node. Used to simplify calling the various optional functions without needing to check if they exist every time.
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

## Refreshes the ViewportControl.
func queue_refresh():
    plugin.update_overlays()

#endregion