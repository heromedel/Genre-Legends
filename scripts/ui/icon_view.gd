class_name IconView
extends Control
## A Control that shows one icon from IconPainter.

var icon := ""
var color := Color(0.85, 0.95, 1.0)


static func make(icon_id: String, size: float, tint: Color = Color(0.85, 0.95, 1.0)) -> IconView:
	var view := IconView.new()
	view.icon = icon_id
	view.color = tint
	view.custom_minimum_size = Vector2(size, size)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view


func _draw() -> void:
	IconPainter.draw(self, icon, Rect2(Vector2.ZERO, size), color)
