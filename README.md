# J-Gizmos

A Godot 4 editor plugin that lets you add custom interactive gizmos to any 2D node in the editor viewport — draggable handles, resizable rectangles, and more — with full undo/redo integration baked in.

---

## Installation

1. Copy the `J-Gizmos` folder into your project's `addons/` directory.
2. In the Godot editor, go to **Project → Project Settings → Plugins** and enable **Javlin_Godot_Plugin**.

---

## How It Works

The plugin watches the editor selection. When a node is selected that has a `gizmos` array property, the plugin automatically mounts each gizmo in that array onto the editor viewport. No scene setup is required — gizmos live entirely in your node's script.

**Minimum requirement:** your node script must expose a `var gizmos : Array = []` property and populate it with gizmo instances.

```gdscript
@tool
extends Node2D

var gizmos : Array = []

func _ready():
    if not Engine.is_editor_hint():
        return

    var handle := J_Gizmo2D_Handle.new()
    handle.quick_setup( _on_drag, "_on_undo", "_on_redo", "Move Handle" )
    gizmos.append( handle )
```

---

## Gizmo Classes

### `J_Gizmo` *(base)*
The root Resource class all gizmos extend. Handles canvas lifecycle, owner/reference-node tracking, and the undo/redo plumbing.

**Key exported properties**

| Property | Type | Description |
|---|---|---|
| `actionName` | `String` | Label shown in the editor's undo/redo history. |
| `onUndo` | `String` | Name of the method on the owner node called when undoing. |
| `onRedo` | `String` | Name of the method on the owner node called when redoing. |
| `overrideUndoRedo` | `String` | If set, completely replaces the built-in undo/redo system with a custom method. |

Undo/redo callbacks receive a `Dictionary` whose structure depends on the gizmo type (documented per class below).

---

### `J_Gizmo2D` *(2D base)*
Extends `J_Gizmo`. Adds viewport transform helpers and positions the canvas relative to the owner node's global position and rotation.

| Property | Type | Description |
|---|---|---|
| `useReferenceRotation` | `bool` | When `true`, the canvas rotates with the reference node. |
| `referenceNode` | `Object` | Optional override for position/rotation source. Accepts a `Node`, `CanvasItem`, or `Gizmo2D_RefNode`. |

---

### `J_Gizmo2D_Handle`
A draggable handle (circle or square) that can be placed anywhere in the owner node's local space.

**Undo/redo dict:** `{ oldPosition: Vector2, newPosition: Vector2 }`

#### Quick setup
```gdscript
handle.quick_setup( dragCallable, "undo_func", "redo_func", "Action Name" )
```

#### Key properties

| Property | Type | Description |
|---|---|---|
| `position` | `Vector2` | Handle position in the owner's local space. |
| `handleVisual` | `HANDLE_VISUAL` | `CIRCLE`, `SQUARE`, or `CUSTOM`. |
| `useOwnerRotation` | `bool` | Whether the handle's position is rotated with its owner. |
| `gizmoSize` | `float` | Radius/half-size of the handle. |
| `gizmoColor1` | `Color` | Fill color. |
| `gizmoColor2` | `Color` | Outline color. |
| `offset` | `float` | Distance the handle is drawn from its logical position. |
| `gizmoOffsetVector` | `Vector2` | Direction of the offset. |

#### Signals

| Signal | Description |
|---|---|
| `on_grab(gizmo)` | Fired when the handle is clicked. |
| `on_release(gizmo)` | Fired when the handle is released. |
| `on_drag(dragPos, dragVector, gizmo)` | Fired every frame while dragging. |
| `on_drag_cancel(gizmo)` | Fired on right-click during a drag. If nothing is connected, the plugin automatically calls the undo function. |
| `on_hover(gizmo)` | Fired when the mouse enters the handle. |
| `on_unhover(gizmo)` | Fired when the mouse leaves the handle. |
| `pre_draw(canvas, gizmo)` | Fired before drawing, every frame. |
| `on_custom_draw(canvas, gizmo)` | Fired in place of default drawing when `handleVisual` is `CUSTOM`. |

---

### `J_Gizmo2D_Rect`
A rectangular gizmo with an optional draggable handle on each corner. Useful for resizing boxes, collision shapes, regions, etc.

If exactly three of the four corner handles are enabled, the gizmo locks the handle-less corner in place, making it easier to resize from a fixed anchor.

**Undo/redo dict:** `{ oldSize: Vector2, newSize: Vector2, newOffset: Vector2 }`

#### Quick setup
```gdscript
rect_gizmo.quick_setup( handle_drag_callable, "undo_func", "redo_func", "Resize" )
rect_gizmo.quick_set_handles( true, true, true, true )  # TL, TR, BL, BR
```

#### Key properties

| Property | Type | Description |
|---|---|---|
| `rect` | `Rect2` | The gizmo's rectangle in local space. |
| `drawRect` | `bool` | Draw a preview rectangle outline. |
| `rectColor` | `Color` | Color of the preview rectangle. |
| `handleTL/TR/BL/BR` | `bool` | Enable/disable each corner handle. |
| `handleSize` | `float` | Size of the corner handles. |
| `handleOffset` | `float` | How far handles are offset from their corner. |
| `handleVisual` | `HANDLE_VISUAL` | Visual style shared by all handles. |

#### Signals

| Signal | Description |
|---|---|
| `on_handle_drag(offset, size, gizmo)` | Fired while any corner handle is dragged. |
| `on_cancel_rect_change(gizmo)` | Fired when a drag is cancelled. |
| `on_handle_hover(handle, gizmo)` | Fired when the mouse enters a corner handle. |
| `on_handle_unhover(handle, gizmo)` | Fired when the mouse leaves a corner handle. |
| `on_draw(canvas, gizmo)` | Fired during drawing, after the preview rectangle. |

---

### `Gizmo2D_RefNode`
A lightweight Resource that acts as a positional/rotational reference for a gizmo when you don't want to use a scene node.

```gdscript
var ref := Gizmo2D_RefNode.new()
ref.position = Vector2(100, 50)
handle.referenceNode = ref
```

| Property | Signals |
|---|---|
| `position : Vector2` | `position_changed(new, old)` |
| `rotation : float` | `rotation_changed(new, old)` |
| `scale : Vector2` | `scale_changed(new, old)` |

---

## Subgizmos

Any gizmo can be set up as a subgizmo of another gizmo. The subgizmo will inherit the owner and canvas of its parent and automatically update when the parent's reference node changes.

```gdscript
sub_handle.setup_as_subgizmo( parent_gizmo )
```

---

## Full Example

```gdscript
@tool
extends Node2D

var gizmos : Array = []
var my_point : Vector2 = Vector2(50, 0)

func _ready():
    if not Engine.is_editor_hint():
        return

    var handle := J_Gizmo2D_Handle.new()
    handle.position = my_point
    handle.quick_setup( _on_drag, "_on_undo", "_on_redo", "Move Point" )
    gizmos.append( handle )

func _on_drag( drag_pos : Vector2, _drag_vec : Vector2, _gizmo ) -> void:
    my_point = drag_pos
    gizmos[0].position = my_point

func _on_undo( args : Dictionary ) -> void:
    my_point = args.oldPosition
    gizmos[0].position = my_point

func _on_redo( args : Dictionary ) -> void:
    my_point = args.newPosition
    gizmos[0].position = my_point
```

---

## License

See [LICENSE](LICENSE).
