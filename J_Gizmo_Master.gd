@tool
extends EditorPlugin
class_name J_Gizmo_Master

var gizmos : Array = []
var grabbedGizmo : J_Gizmo = null

func _enter_tree():
    self.name = 'J_Gizmo_Master'

func _handles( obj ):
    var selection : Array = get_editor_interface().get_selection().get_selected_nodes()
    gizmos.clear()
    grabbedGizmo = null

    for node in selection:
        if node.get('gizmos'):
            for gizmo in node.gizmos:
                if gizmo == null:
                    continue
                gizmo.plugin = self
                gizmo.owner = node
                gizmos.append( gizmo )
            # gizmos += node.setup_gizmos( self )
    
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

func _forward_canvas_draw_over_viewport(viewport_control) -> void:
    for gizmo in gizmos:
        gizmo._on_canvas_draw_over_viewport(viewport_control)