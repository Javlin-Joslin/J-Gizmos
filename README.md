# J-Gizmos

J-Gizmos is a Godot 4 editor plugin for building custom 2D editor gizmos without writing a full editor tool from scratch.

It lets your tool scripts expose gizmo resources on selected nodes, and handles:
- drawing in the 2D editor viewport
- mouse hover / drag / release input
- editor undo/redo integration
- reusable handle and rectangle gizmo types

## What It Solves

If you have a custom Control or Node2D and want draggable editor handles for things like:
- resize bounds
- anchor points
- effect regions
- custom layout tools
- plugin-specific handles

J-Gizmos gives you a lightweight way to do that by attaching gizmo resources to the node itself.

## Current Gizmo Types

### J_Gizmo2D_Handle
A single draggable 2D handle.

Use it when you need:
- one point to drag
- custom handle visuals
- drag callbacks and undo/redo

Key signals:
- on_grab
- on_release
- on_drag
- on_drag_cancel
- on_hover
- on_unhover
- on_custom_draw
- post_draw

Undo/redo callback args:
- { oldPosition: Vector2, newPosition: Vector2 }

### J_Gizmo2D_Rect
A rectangle gizmo with optional corner handles.

Use it when you need:
- resize boxes
- draggable rectangle corners
- editor-visible bounds previews

Key signals:
- on_rect_change
- on_cancel_rect_change
- on_handle_hover
- on_handle_unhover
- on_handle_grab
- on_handle_release
- on_handle_draw
- post_handle_draw

Undo/redo callback args:
- { oldSize: Vector2, newSize: Vector2, newOffset: Vector2 }

## Installation

1. Copy the J-Gizmos folder into your project’s addons folder.
2. Enable J-Gizmos in Project Settings > Plugins.
3. Select a node that exposes a gizmos array to see its gizmos in the 2D editor.

## How It Works

J-Gizmos looks for a property named gizmos on the currently selected node.

That property should return an array of gizmo resources, for example:
- Array[J_Gizmo2D]
- Array containing J_Gizmo2D_Handle
- Array containing J_Gizmo2D_Rect

When the node is selected in the editor, the plugin:
- creates a drawing canvas for each gizmo
- forwards viewport input to the gizmos
- refreshes the gizmos after undo/redo

## Quick Start

Here is a minimal rectangle gizmo example on a tool script:

~~~gdscript
@tool
extends Control

@export var gizmos: Array[J_Gizmo2D] = []:
    get:
        if gizmos.is_empty():
            var rect_gizmo := J_Gizmo2D_Rect.new()
            gizmos = [rect_gizmo]

            rect_gizmo.size = size
            rect_gizmo.handleTR = true
            rect_gizmo.handleBL = true
            rect_gizmo.handleBR = true

            rect_gizmo.on_rect_change.connect(_on_rect_change)
            rect_gizmo.onUndo = "undo_rect_change"
            rect_gizmo.onRedo = "redo_rect_change"

        return gizmos

func _on_rect_change(offset: Vector2, new_size: Vector2) -> void:
    size = new_size

func undo_rect_change(args: Dictionary) -> void:
    size = args.oldSize
    if not gizmos.is_empty():
        gizmos[0].size = size

func redo_rect_change(args: Dictionary) -> void:
    size = args.newSize
    if not gizmos.is_empty():
        gizmos[0].size = size