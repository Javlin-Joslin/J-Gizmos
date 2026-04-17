@tool
extends J_Gizmo2D

## A rectangular gizmo with optional handles on each corner that can be used for resizing or other such tasks via the gizmo's many [code]Signals[/code] and undo/redo callbacks.[br]
## An extra feature of this gizmo is that if only 3 of the 4 handles are enabled, the gizmo will lock the corner with no handle into place to make resizing and positioning more precise.[br]
## undo callback arguement Dict: [code]{ oldSize : Vector2, newSize : Vector2, newOffset : Vector2 }[/code][br]
## redo callback arguement Dict: [code]{ oldSize : Vector2, newSize : Vector2, newOffset : Vector2 }[/code][br]
class_name J_Gizmo2D_Rect

#region Display Rect Variables
## If true, the gizmo will draw a preview rectangle representing the gizmo's area.
@export var drawRect : bool = true : 
    set(inp):
        drawRect = inp
        on_var_changed()
## The color of the preview rectangle drawn when [code]drawRect[/code] is set to true.
@export var rectColor : Color = Color.HOT_PINK :
    set(inp):
        rectColor = inp
        on_var_changed()
        for gizmo in gizmos:
            if gizmo != null:
                gizmo.rectColor = rectColor
## The thickness of the preview rectangle drawn when [code]drawRect[/code] is set to true.
@export var rectThickness : float = 2.0 :
    set(inp):
        rectThickness = inp
        on_var_changed()
#endregion

#region Handle Display Variables
## If true, there will be a handle in the top left corner of the gizmo.
@export var handleTL : bool = false :
    set(inp):
        handleTL = inp
        on_var_changed()
        _setupGizmos()
## If true, there will be a handle in the top right corner of the gizmo.
@export var handleTR : bool = false :
    set(inp):
        handleTR = inp
        on_var_changed()
        _setupGizmos()
## If true, there will be a handle in the bottom left corner of the gizmo.
@export var handleBL : bool = false :
    set(inp):
        handleBL = inp
        on_var_changed()
        _setupGizmos()
## If true, there will be a handle in the bottom right corner of the gizmo.
@export var handleBR : bool = false :
    set(inp):
        handleBR = inp
        on_var_changed()
        _setupGizmos()

@export_group( "Handle Visuals" )
## Size of this gizmo's handles.
@export var handleSize : float = 5.0 :
    set(inp):
        handleSize = inp
        on_var_changed()
        for gizmo in gizmos:
            if gizmo != null:
                gizmo.gizmoSize = handleSize
## Outline size of this gizmo's handles when not hovered over.
@export var handleOutlineSize : float = 1.0 :
    set(inp):
        handleOutlineSize = inp
        on_var_changed()
        for gizmo in gizmos:
            if gizmo != null:
                gizmo.gizmoOutline = handleOutlineSize
## Outline size of this gizmo's handles when hovered over.
@export var handleActiveOutlineSize : float = 3.0 :
    set(inp):
        handleActiveOutlineSize = inp
        on_var_changed()
        for gizmo in gizmos:
            if gizmo != null:
                gizmo.gizmoOutlineActive = handleActiveOutlineSize
## How far from the corner the handles will be displayed.
@export var handleOffset : float = 14.0 :
    set(inp):
        handleOffset = inp
        on_var_changed()
        for gizmo in gizmos:
            if gizmo != null:
                gizmo.offset = handleOffset
## Visual style of this gizmo's handles. If set to [code]HANDLE_VISUAL.CUSTOM[/code], the [code]on_handle_draw[/code] signal will be emitted when drawing the handles, allowing you to draw custom visuals for the handles via the [code]on_custom_draw[/code] signal.
@export var handleVisual : J_Gizmo2D_Handle.HANDLE_VISUAL = J_Gizmo2D_Handle.HANDLE_VISUAL.CIRCLE :
    set(inp):
        handleVisual = inp
        on_var_changed()
        for gizmo in gizmos:
            if gizmo != null:
                gizmo.handleVisual = handleVisual
#endregion
@export_group("")

## Used by the gizmo for setting up the handles.
enum _GIZMO_ENUM { TL, TR, BL, BR }
## Used by the gizmo for setting up the handles.
const GIZMO_VECTORS : Array[ Vector2 ] = [ Vector2( -1.0, -1.0 ), Vector2( 1.0, -1.0 ), Vector2( -1.0, 1.0 ), Vector2( 1.0, 1.0 ) ]
## Used by the gizmo for setting up the handles.
var _gizmosActiveAxis : Array = [ Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO ]
## The Array that holds all the handle subgizmos used by this gizmo. Automatically setup and populated when the handle display variables are changed.
var gizmos : Array[ J_Gizmo2D_Handle ] = []

#region Settings Variables
## The size of this gizmo's rectangle. Emits [code]on_rect_change[/code] when changed.
@export var size : Vector2 = Vector2( 30.0, 30.0 ):
    set(inp):
        if inp == size:
            return
        
        size = inp
        _rect.size = size
        on_rect_change.emit( _rect.position, _rect.size )
        on_var_changed()

        _rect.position = Vector2.ZERO
        _position_gizmos()

## Virtual Rect used for calculations.
var _rect : Rect2 = Rect2( Vector2.ZERO, size )
## Virtual Rect used for storing the previous rect when dragging handles for undo/redo purposes.
var oldRect : Rect2 = Rect2( Vector2.ZERO, size )

#endregion

#region Signals
## Emitted when the gizmo is drawn, after the preview rectangle.
signal on_draw( canvas : Gizmo_Canvas, this_gizmo : J_Gizmo2D_Rect )
## Emitted when the gizmo's rect is changed.
signal on_rect_change( offset : Vector2, size : Vector2 )
## Emitted when the gizmo's rect change is canceled.
signal on_cancel_rect_change( this_gizmo : J_Gizmo2D_Rect )
## Emitted when one of the gizmo's handles is hovered over.
signal on_handle_hover( handle : J_Gizmo2D_Handle, this_gizmo : J_Gizmo2D_Rect )
## Emitted when one of the gizmo's handles stops being hovered over.
signal on_handle_unhover( handle : J_Gizmo2D_Handle, this_gizmo : J_Gizmo2D_Rect )
## Emitted when one of the gizmo's handles are grabbed.
signal on_handle_grab( handle : J_Gizmo2D_Handle, this_gizmo : J_Gizmo2D_Rect,  )
## Emitted when one of the gizmo's handles are released after being grabbed.
signal on_handle_release( handle : J_Gizmo2D_Handle, this_gizmo : J_Gizmo2D_Rect )
## Emitted when the handle is drawn while [code]handleVisual[/code] is set to [code]HANDLE_VISUAL.CUSTOM[/code].
signal on_handle_draw( handleCanvas : Gizmo_Canvas, handle : J_Gizmo2D_Handle, this_gizmo : J_Gizmo2D_Rect )
## Emitted after a handle is drawn but before it leaves the draw function, allowing for aditional custom drawing on top of the handle.
signal post_handle_draw( handleCanvas : Gizmo_Canvas, handle : J_Gizmo2D_Handle, this_gizmo : J_Gizmo2D_Rect )
#endregion

#region Gizmo Setup

## Generates and sets up all of this gizmo's the handle subgizmos. Called automatically.
func _setupGizmos( ) -> void:
    for gizmo in gizmos:
        if gizmo != null:
            gizmo.plugin = null
    
    gizmos.clear()
    var activeGizmos : Array[ bool ] = [ handleTL, handleTR, handleBL, handleBR ]
    _gizmosActiveAxis = [ Vector2.ONE, Vector2.ONE, Vector2.ONE, Vector2.ONE ]


    if activeGizmos.count( true ) == 3:
        if not handleTL:
            _gizmosActiveAxis[ _GIZMO_ENUM.BL ] = Vector2( 0.0, 1.0 )
            _gizmosActiveAxis[ _GIZMO_ENUM.TR ] = Vector2( 1.0, 0.0 )
        elif not handleTR:
            _gizmosActiveAxis[ _GIZMO_ENUM.BR ] = Vector2( 0.0, 1.0 )
            _gizmosActiveAxis[ _GIZMO_ENUM.TL ] = Vector2( 1.0, 0.0 )
        elif not handleBL:
            _gizmosActiveAxis[ _GIZMO_ENUM.TL ] = Vector2( 0.0, 1.0 )
            _gizmosActiveAxis[ _GIZMO_ENUM.BR ] = Vector2( 1.0, 0.0 )
        elif not handleBR:
            _gizmosActiveAxis[ _GIZMO_ENUM.TR ] = Vector2( 0.0, 1.0 )
            _gizmosActiveAxis[ _GIZMO_ENUM.BL ] = Vector2( 1.0, 0.0 )

    for gizmoIndex in range(4):
        if ! activeGizmos[ gizmoIndex ]:
            gizmos.append( null )
            continue
        
        var newGizmo := J_Gizmo2D_Handle.new()
        var gizmoID : String = _GIZMO_ENUM.find_key( gizmoIndex )

        newGizmo.set_meta( 'gizmo_id', gizmoID )
        newGizmo.plugin = plugin
        newGizmo.setup_as_subgizmo( self )

        newGizmo.handleVisual = handleVisual
        newGizmo.offset = handleOffset
        newGizmo.gizmoSize = handleSize
        newGizmo.gizmoOutline = handleOutlineSize
        newGizmo.gizmoOutlineActive = handleActiveOutlineSize

        newGizmo.on_drag.connect( _on_handle_drag )
        newGizmo.on_drag_cancel.connect( _on_cancel )
        newGizmo.on_grab.connect( _on_handle_grabbed )
        newGizmo.on_release.connect( _on_handle_released )
        newGizmo.on_hover.connect( on_handle_hover.emit.bind( self ) )
        newGizmo.on_unhover.connect( on_handle_unhover.emit.bind( self ) )
        newGizmo.on_custom_draw.connect( on_handle_draw.emit.bind( self ) )
        newGizmo.post_draw.connect( post_handle_draw.emit.bind( self ) )
        newGizmo.overrideUndoRedo = '_blank_handle_undoredo'

        newGizmo.gizmoOffsetVector = GIZMO_VECTORS[ gizmoIndex ] * _gizmosActiveAxis[ gizmoIndex ]
        gizmos.append( newGizmo )
    
    _position_gizmos()

## This is used to override the subgizmo handle undo redo systems.
func _blank_handle_undoredo() -> void:
    pass

func _position_gizmos() -> void:
    for gizmo in gizmos:
        if gizmo == null:
            continue
        gizmo.get_meta( 'gizmo_id' )
        match gizmo.get_meta( 'gizmo_id' ):
            'TL':
                gizmo.position = _rect.position
            'TR':
                gizmo.position = Vector2( _rect.position.x+_rect.size.x, _rect.position.y )
            'BL':
                gizmo.position = Vector2( _rect.position.x, _rect.position.y+_rect.size.y )
            'BR':
                gizmo.position = Vector2( _rect.position.x+_rect.size.x, _rect.position.y+_rect.size.y )

#endregion

#region Input
func _on_canvas_gui_input( event ) -> bool:    
    super._on_canvas_gui_input(event)
    for gizmo in gizmos:
        if gizmo != null and gizmo._on_canvas_gui_input( event ):
            return( true )

    return false

## Called by the handle subgizmos when they are grabbed. Used to store the current rect for undo/redo purposes and emit the [code]on_handle_grab[/code] signal.
func _on_handle_grabbed( handle : J_Gizmo2D_Handle ) -> void:
    oldRect = _rect
    on_handle_grab.emit( handle, self )

## Called by the handle subgizmos when they are released. Used to emit the [code]on_handle_release[/code] signal and setup the undo/redo actions for the handle drag.
func _on_handle_released( handle : J_Gizmo2D_Handle ) -> void:
    on_handle_release.emit( handle, self )
    _setup_undo_redo( 
        { 'oldSize' : oldRect.size, 'newSize' : _rect.size, 'newOffset' : _rect.position },
        { 'oldSize' : oldRect.size, 'newSize' : _rect.size, 'newOffset' : _rect.position }, 
        actionName 
    )

## Enum containing the Different ways a handle subgizmo interacts with different axes.[br]
## - POSITIONAL : 0 - The handle both scales and repositions the _rect on the axis ( emitting an on_rect_change signal with both a real offset and size vector on that axis ).[br]
## - SIZE : 1 - The handle only scales the _rect on the axis ( emitting an on_rect_change signal with a zero offset vector on that axis ).[br]
## - LOCKED : 2 - The handle is unable to modify the _rect on the axis ( emitting an on_rect_change signal with a zero size vector on that axis ).
enum HANDLE_TYPE_ENUM { POSITIONAL, SIZE, LOCKED }
## Handles the dragging of the handle subgizmos, modifying the gizmo's rect based on the type of handle being dragged and emitting the appropriate signals. Automatically connected to the handle subgizmos when they are generated in _setupGizmos.
func _on_handle_drag( dragPos : Vector2, handle : J_Gizmo2D_Handle ) -> void:
    
    
    var addSubVect : Vector2 = Vector2.ONE
    var xType : HANDLE_TYPE_ENUM
    var yType : HANDLE_TYPE_ENUM

    match handle.get_meta( 'gizmo_id' ):
        'TL':
            xType = HANDLE_TYPE_ENUM.POSITIONAL
            yType = HANDLE_TYPE_ENUM.POSITIONAL
        'TR':
            xType = HANDLE_TYPE_ENUM.SIZE
            yType = HANDLE_TYPE_ENUM.POSITIONAL
        'BL':
            xType = HANDLE_TYPE_ENUM.POSITIONAL
            yType = HANDLE_TYPE_ENUM.SIZE
            
        'BR':
            xType = HANDLE_TYPE_ENUM.SIZE
            yType = HANDLE_TYPE_ENUM.SIZE
    
    if _gizmosActiveAxis[ _GIZMO_ENUM[ handle.get_meta( 'gizmo_id' ) ] ].x == 0.0:
        xType = HANDLE_TYPE_ENUM.LOCKED
    if _gizmosActiveAxis[ _GIZMO_ENUM[ handle.get_meta( 'gizmo_id' ) ] ].y == 0.0:
        yType = HANDLE_TYPE_ENUM.LOCKED

    var modifiedRect = _rect
    
    var originalPosition : Vector2 = _rect.position
    var originalSize : Vector2 = _rect.size

    modifiedRect = _calc_handle_mod( modifiedRect, xType, dragPos, 0 )
    modifiedRect = _calc_handle_mod( modifiedRect, yType, dragPos, 1 )

    owner.position += modifiedRect.position - originalPosition
    size = modifiedRect.size

    _position_gizmos()

## Calculates how the handle subgizmo modifies the given rect on the given axis. Used by the _on_handle_drag function.
func _calc_handle_mod( modifiedRect : Rect2, handleType : HANDLE_TYPE_ENUM, dragPos : Vector2, axis : int ) -> Rect2:
    match handleType:
        HANDLE_TYPE_ENUM.POSITIONAL:
            modifiedRect.size[ axis ] += _rect.position[ axis ] - dragPos[ axis ]
            modifiedRect.position[ axis ] -= _rect.position[ axis ] - dragPos[ axis ]

            if modifiedRect.size[axis] <= 0:
                modifiedRect.position[ axis ] += modifiedRect.size[ axis ]
                modifiedRect.size[ axis ] = 0
                
        HANDLE_TYPE_ENUM.SIZE:
            modifiedRect.size[ axis ] += dragPos[ axis ] - (_rect.position[ axis ] + _rect.size[ axis ])

            if modifiedRect.size[axis] <= 0:
                modifiedRect.size[ axis ] = 0
    
    
    return( modifiedRect )

## Called by the handle subgizmos when a drag is canceled. Used to emit the [code]on_cancel_rect_change[/code] signal and reset the gizmo's rect to the old rect stored when the handle was grabbed.
func _on_cancel( handle : J_Gizmo2D_Handle ) -> void:
    
    if on_cancel_rect_change.has_connections():
        on_cancel_rect_change.emit( self )

    elif not _try_using( onUndo, [ { 'oldSize' : oldRect.size, 'newSize' : _rect.size, 'newOffset' : _rect.position } ] ):
        if owner.get('name') != null:
            printerr( 'Warning: No undo function defined for gizmo in ' , owner.name,'.' )
        else:
            printerr( 'Warning: No undo function defined for gizmo.' )

    plugin.queue_refresh()


#endregion

#region Drawing

## Draws the gizmo, including the preview rectangle and the handle subgizmos. Automatically called by the plugin.
func draw_gizmo() -> void:
    super.draw_gizmo()
    var viewportScale : float = get_viewport_transform().x.x
    
    if drawRect:
        var drawnRect : Rect2 = _rect
        canvas.draw_rect( drawnRect, rectColor, false, rectThickness/viewportScale )

    on_draw.emit( canvas, self )

    for gizmo in gizmos:
        if gizmo != null:
            gizmo.draw_gizmo()
    
