@tool
extends J_Gizmo
class_name J_GizmoRect

static func new_gizmo( pluginNode : EditorPlugin, ownerNode : Node ) -> J_GizmoRect:
    var newGizmo = J_GizmoRect.new()
    newGizmo.plugin = pluginNode
    newGizmo.owner = ownerNode
    return( newGizmo )

@export var gizmoTL : J_Gizmo2D_Handle :
    set(inp):
        setupGizmo( inp, gizmoTL )
        gizmoTL = inp
@export var gizmoTR : J_Gizmo2D_Handle :
    set(inp):
        setupGizmo( inp, gizmoTR )
        gizmoTR = inp
@export var gizmoBL : J_Gizmo2D_Handle :
    set(inp):
        setupGizmo( inp, gizmoBL )
        gizmoBL = inp
@export var gizmoBR : J_Gizmo2D_Handle :
    set(inp):
        setupGizmo( inp, gizmoBR )
        gizmoBR = inp

func setupGizmo( newGizmo : J_Gizmo2D_Handle, oldGizmo : J_Gizmo2D_Handle ) -> void:
    if newGizmo != null:
        if gizmoTL == newGizmo:
            gizmoTL = null
        if gizmoTR == newGizmo:
            gizmoTR = null
        if gizmoBL == newGizmo:
            gizmoBL = null
        if gizmoBR == newGizmo:
            gizmoBR = null
        
        newGizmo.owner = self
        newGizmo.referenceNode = owner
        newGizmo.changed.connect( emit_changed )
    
    if oldGizmo != null:
        oldGizmo.changed.disconnect( emit_changed )
    


@export var size : Vector2 = Vector2( 30.0, 30.0 ):
    set(inp):
        size.x = max( inp.x, 0.0001 )
        size.y = max( inp.y, 0.0001 )
        _rect.size = size
        emit_changed()
var _rect : Rect2 = Rect2( Vector2.ZERO, size )

@export var drawRect : bool = true
@export var rectColor : Color = Color.HOT_PINK

enum ORIENTATION_ENUM { Centered, From_TL, From_TR, From_BL, From_BR }
@export var orientation : ORIENTATION_ENUM = ORIENTATION_ENUM.From_TL


#region Input
func _on_canvas_gui_input( event ) -> bool:
    return( false )

#region Drawing
func _on_canvas_draw_over_viewport( viewport_control ) -> void:
    _draw_gizmo( viewport_control )

func _draw_gizmo( viewport_control ) -> void:
    if drawRect:
        match orientation:
            ORIENTATION_ENUM.Centered:
                _rect.position = Vector2( -size.x/2.0, -size.y/2.0 )
            
            ORIENTATION_ENUM.From_TL:
                _rect.position = Vector2.ZERO              
            
            ORIENTATION_ENUM.From_TR:
                _rect.position = Vector2( -size.x, 0.0 )
            
            ORIENTATION_ENUM.From_BL:
                _rect.position = Vector2( 0.0, -size.y )
            
            ORIENTATION_ENUM.From_BR:
                _rect.position = Vector2( -size.x, -size.y )
            
            _:
                printerr( "Invalid orientation enum in J_Rect_gizmo resource: " + str(orientation) )
