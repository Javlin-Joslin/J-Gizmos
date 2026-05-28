# J-Gizmos

A Godot 4 editor plugin that makes it easy to add gizmos to any 2D node that automatically position themselves according to the node's position, scale, and rotation with full undo/redo integration baked in.

---

## Installation

1. Copy the `addons` folder into your project.
2. In the Godot editor, go to **Project → Project Settings → Plugins** and enable **Javlin_Gizmos**.

---

## How It Works

The plugin watches the editor selection. When a node is selected that has a `gizmos` array property, the plugin automatically mounts each gizmo in that array onto the editor viewport. No scene setup is required — gizmos live entirely in your node's script.

**Minimal Example:**

```gdscript
@tool
extends Node2D

var gizmos : Array = []

func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	
	var gizmo : J_Gizmo2D_Handle = J_Gizmo2D_Handle.new()
	gizmo.quick_setup(_on_gizmo_drag, '_undo_drag', '_redo_drag')
	gizmo.gizmoOffsetVector = Vector2(0.0, 1.0)
	gizmos.append(gizmo)

func _on_gizmo_drag(_dragPos: Vector2, dragVector: Vector2, _gizmo: J_Gizmo2D_Handle) -> void:
	position += dragVector * scale
```
This will add a single gizmo to the node when selected that can be used to drag the node around.<br>
**Notes:**
- The `@tool` annotation is required for the script to run in the editor.
- The gizmo is automatically positioned as if it was a child of its reference node (by default this is the node containing it) and that is factored into the drag calculations (hence why we multiply the dragVector by the node's scale in order to properly move it when it isn't at default scale).
- The given example will print the error "No valid undo/redo functions defined for gizmo in *node_name*" whenever you let go of the gizmo. Don't panic! This is just the plugin reminding you to set up undo/redo callbacks but the gizmo will work fine without them (though you really should set them up eventually).

**Example Undo/Redo**
```gdscript
func _undo_drag(args : Dictionary) -> void:
	position -= args.totalDragVector * scale

func _redo_drag(args : Dictionary) -> void:
	position += args.totalDragVector * scale
```
Since they are already named in the `quick_setup` call, the plugin will automatically call these methods when an undo/redo action is performed with the gizmo. The `args` dictionary contains the original position of the gizmo (`oldPosition`), the gizmo's position after the drag finished (`newPosition`), and the total vector of the drag from the gizmo's initial position (`totalDragVector`). These values should be able to be used to reverse and reapply any changes made when you drag the gizmo.

---

## Gizmo Classes
Take note that all variables, functions, signals, and enums in these classes have comments in the code itself that show up as documentation when looked at through Godot's "search help" feature in its script editor, just like any of its built-in classes would, so I'm just going to cover the basics here in the readme. For more details on how to use any specific feature, check the code docs!

---
### `J_Gizmo` *(base)*
The root Resource class all gizmos extend. Handles canvas lifecycle, owner/reference-node tracking, and the undo/redo plumbing.

---
### `J_GizmoCanvas`
A simple helper class that, as its name suggests, is what's used by a gizmo to draw on the editor viewport. When a node with gizmos is selected, the plugin creates a canvas for each gizmo and sets it as the gizmo's `canvas` property. The canvas then automatically follows the gizmo's `referenceNode` (or owner node if no reference node is set) around in the viewport, applying its global position and rotation to the canvas transform before running the gizmo's drawing code. This canvas allows for the gizmo to effectively be drawn in the reference node's local space while still being drawn on top of anything else in the viewport. When the node containing the gizmos is deselected, all of its canvases are automatically freed.

---
### `J_Gizmo2D` *(2D base)*
Extends the `J_Gizmo` base class and adds some 2D-specific positioning functions.

---
### `J_Gizmo2D_Handle`
The standard gizmo I use most often. A simple circular or square handle that can be dragged around to manipulate its reference node in some way. It has a ton of variables and signals that make it easy to customize its appearance, how it responds to input, and what it does with said input.

#### How to Setup?
This was actually the gizmo I showed in that minimal example above, but if you need more in depth examples of how to use this gizmo, check out my J_CSG_2D plugin where I use it extensively for modifying custom CSG shapes in the viewport.

---
### `J_Gizmo2D_Rect`
A rectangular gizmo with an optional draggable handle on each corner. Useful for resizing boxes, collision shapes, regions, etc.
If exactly three of the four corner handles are enabled, the gizmo locks the handle-less corner in place, making it easier to resize from a fixed anchor.

#### Quick setup
```gdscript
@tool
extends Node2D

@export var exampleVar : Vector2 = Vector2(10.0, 10.0) :
	set(inp):
		exampleVar = inp
		if gizmos.size() > 0:
			gizmos[0].rect.size = exampleVar # Adjust gizmo size when variable is changed.

var gizmos : Array = []

func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	
	var rectGizmo : J_Gizmo2D_Rect = J_Gizmo2D_Rect.new()
	rectGizmo.quick_setup(_on_gizmo_drag, '_undo_drag', '_redo_drag')
	rectGizmo.quick_set_handles( false, true, true, true )
	rectGizmo.rect = Rect2( Vector2.ZERO, exampleVar )
	gizmos.append(rectGizmo)

func _on_gizmo_drag(_offset: Vector2, size: Vector2, _gizmo: J_Gizmo2D_Rect) -> void:
	exampleVar = size

func _undo_drag(args : Dictionary) -> void:
	exampleVar = args.oldSize

func _redo_drag(args : Dictionary) -> void:
	exampleVar = args.newSize
```
This example sets up a `J_Gizmo2D_Rect` to edit the `exampleVar` variable. The gizmo's size is automatically updated when the variable changes and the variable is updated when the gizmo is dragged. Undo/redo functions are also set up to reverse and reapply the size changes when an undo/redo action is performed with the gizmo.

---
### `J_Gizmo2D_RefNode`
A lightweight Resource that acts as a positional/rotational reference for a gizmo when you don't want to use a scene node.

---
## Subgizmos
In the base `J_Gizmo` class there is a `setup_as_subgizmo` function that makes it easier to setup a gizmo as a "subgizmo". Check out the script for the `J_Gizmo2D_Rect` class for an example of how I use this to make the corner handles into subgizmos of the main rectangle gizmo. Subgizmos are basically just gizmos that are parented to another gizmo instead of a scene node. They follow the parent gizmo around and can be set up to emit signals that the parent gizmo can listen to, making it easy to have multiple gizmos working together as one unit.

---

## License

See [LICENSE](LICENSE) - All versions prior to v1.0 are also released under the MIT License.
