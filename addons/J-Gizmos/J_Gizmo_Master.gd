@tool
extends EditorPlugin
class_name J_Gizmo_Master

const MASTER_NODE_NAME : String = 'J_Gizmo_Master'
var _gizmos : Array = []
var _canvases : Array = []
var grabbedGizmo : J_Gizmo = null

func _enter_tree():
    name = MASTER_NODE_NAME
    var window : Window = get_editor_window()
    window.set_meta( MASTER_NODE_NAME, self )
    
    EditorInterface.get_selection().selection_changed.connect( _on_selection_changed )


#region Static Utils
static func get_editor_window() -> Window:
    return( EditorInterface.get_base_control().get_window() )

static func get_master() -> J_Gizmo_Master:
    var window : Window = get_editor_window()
    if window.has_meta( MASTER_NODE_NAME ):
        return( window.get_meta( MASTER_NODE_NAME ) )
    
    printerr( 'Error: No J_Gizmo_Master found in the scene tree. This should never happen, make sure the J-Gizmos plugin is enabled.' )
    return( null )

static func get_frame_duration() -> float:
    return( 1.0 / Engine.get_frames_per_second() )

#endregion

#region Input
func _on_selection_changed():
    for canvas in _canvases:
        # Must clear the canvas's reference to the gizmo before freeing it to avoid errors from the canvas trying to call
        # functions on the gizmo after it's been freed.
        canvas.ownerGizmo = null
        canvas.queue_free()
    
    _canvases.clear()
    _gizmos.clear()
    grabbedGizmo = null

    var selection : Array = EditorInterface.get_selection().get_selected_nodes()

    for node in selection:
        if node.get('gizmos'):
            for gizmo in node.gizmos:
                if gizmo == null:
                    continue
                
                gizmo.owner = node
                gizmo.canvas = Gizmo_Canvas.new()
                gizmo.canvas.ownerGizmo = gizmo
                gizmo.get_target_viewport().add_child( gizmo.canvas )
                _canvases.append( gizmo.canvas )

                _gizmos.append( gizmo )

func _handles( obj ):
    # Pause for a frame to allow the _on_selection_changed function to finish running and populate the _gizmos array before 
    # checking if there are any gizmos to handle.
    await get_tree().process_frame
    if _gizmos.size() > 0:
        return(true)

    return( false )

func _forward_canvas_gui_input(event) -> bool:
    if grabbedGizmo != null:
        return ( grabbedGizmo._on_canvas_gui_input(event) )
    
    
    for gizmo in _gizmos:
        if gizmo._on_canvas_gui_input(event):
            return(true)
    
    return( false )

#endregion

#region Drawing
var _refresh_queued : bool = false
func queue_refresh():
    if _refresh_queued == false:
        _refresh_queued = true
        await get_tree().process_frame
        _on_selection_changed()
        _refresh_queued = false

func _forward_canvas_draw_over_viewport(viewport_control) -> void:
    for gizmo in _gizmos:
        gizmo._on_canvas_draw_over_viewport(viewport_control)

#endregion

func _exit_tree():
    var window : Window = get_editor_window()
    if window.has_meta( 'J_Gizmo_Master' ):
        window.remove_meta( 'J_Gizmo_Master' )
    
    for canvas in _canvases:
        canvas.queue_free()