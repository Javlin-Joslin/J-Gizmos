@tool
extends EditorPlugin
class_name J_Gizmo_Master

var gizmos : Array = []
var grabbedGizmo : JGizmo = null

func _enter_tree():
    self.name = 'J_Gizmo_Master'

func _handles( obj ):
    var selection : Array = get_editor_interface().get_selection().get_selected_nodes()
    gizmos.clear()
    grabbedGizmo = null

    for node in selection:
        if node.get('use_gizmos'):
            gizmos += node.setup_gizmos( self )
    
    if gizmos.size() > 0:
        return(true)

    return( false )

func _forward_canvas_gui_input(event) -> bool:
    if grabbedGizmo != null:
        return ( grabbedGizmo._on_canvas_gui_input(event) )
    
    for gizmo in gizmos:
        if gizmo._on_canvas_gui_input(event):
            return(true)
    
    return( false )

func _forward_canvas_draw_over_viewport(viewport_control):
    for gizmo in gizmos:
        gizmo._draw_on_canvas(viewport_control)