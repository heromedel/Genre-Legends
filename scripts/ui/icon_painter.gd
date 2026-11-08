class_name IconPainter
## One vector icon set for the whole game: tech, mission types, menus and HUD.
## Icons are drawn in a -1..1 box and scaled to whatever rect they're given.


static func draw_text(ci: CanvasItem, text: String, rect: Rect2, color: Color) -> void:
	var font_size := int(rect.size.y * 0.6)
	ci.draw_string(UiKit.font("bold"), Vector2(rect.position.x, rect.get_center().y + font_size * 0.35), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, color)


static func draw(ci: CanvasItem, icon: String, rect: Rect2, color: Color) -> void:
	var c := rect.get_center()
	var s := minf(rect.size.x, rect.size.y) * 0.5
	var w := maxf(1.5, s * 0.12)
	var p := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * s
	match icon:
		# ---- tech
		"pulse_driver":
			for i in 3:
				ci.draw_line(p.call(-0.8 + i * 0.5, 0.35), p.call(-0.3 + i * 0.5, -0.35), color, w * 1.4, true)
		"thunder_lance":
			ci.draw_polyline(PackedVector2Array([p.call(-0.2, -0.9), p.call(0.25, -0.1), p.call(-0.15, 0.05), p.call(0.3, 0.9)]), color, w * 1.3, true)
		"hex_repeater":
			Art.shape(ci, Transform2D(0, c) * Art.ngon(6, s * 0.65), Art.with_alpha(color, 0.25), color, w)
			ci.draw_circle(c, s * 0.2, color)
		"arc_blade":
			ci.draw_arc(c + Vector2(-s * 0.3, s * 0.3), s * 0.95, -PI * 0.5, 0.0, 16, color, w * 1.6, true)
			ci.draw_line(p.call(-0.6, 0.6), p.call(-0.3, 0.3), color, w * 2.0, true)
		"swarm_pods":
			for i in 3:
				var base: Vector2 = p.call(-0.6 + i * 0.6, 0.6)
				ci.draw_line(base, base + Vector2(0, -s * 1.0), color, w, true)
				ci.draw_colored_polygon(PackedVector2Array([base + Vector2(0, -s * 1.2), base + Vector2(-s * 0.15, -s * 0.9), base + Vector2(s * 0.15, -s * 0.9)]), color)
		"orbital_halo":
			ci.draw_arc(c, s * 0.7, 0, TAU, 24, Art.with_alpha(color, 0.5), w, true)
			for i in 3:
				Art.shape(ci, Transform2D(i, c + Vector2.from_angle(TAU * i / 3.0) * s * 0.7) * Art.star(4, s * 0.28, s * 0.1), color, color, 1.0)
		"starfall":
			ci.draw_circle(p.call(0.35, 0.35), s * 0.32, color)
			for i in 3:
				ci.draw_line(p.call(0.2 - i * 0.25, 0.2 - i * 0.05), p.call(-0.6 - i * 0.2, -0.6 - i * 0.05), Art.with_alpha(color, 0.8 - i * 0.2), w, true)
		"mirror_aegis":
			ci.draw_arc(c, s * 0.8, -2.3, 2.3, 20, color, w * 1.4, true)
			ci.draw_line(p.call(-0.8, 0.0), p.call(0.1, 0.0), color, w, true)
			ci.draw_line(p.call(0.1, 0.0), p.call(-0.4, -0.5), color, w, true)
		"graze_engine":
			ci.draw_circle(c, s * 0.25, color)
			for i in 6:
				var a := TAU * i / 6.0
				ci.draw_line(c + Vector2.from_angle(a) * s * 0.45, c + Vector2.from_angle(a + 0.4) * s * 0.9, color, w, true)
		"overheat_core":
			ci.draw_colored_polygon(PackedVector2Array([p.call(0, -0.95), p.call(0.55, 0.2), p.call(0.3, 0.8), p.call(-0.3, 0.8), p.call(-0.55, 0.2)]), Art.with_alpha(color, 0.35))
			ci.draw_polyline(PackedVector2Array([p.call(0, -0.95), p.call(0.55, 0.2), p.call(0.3, 0.8), p.call(-0.3, 0.8), p.call(-0.55, 0.2), p.call(0, -0.95)]), color, w, true)
		"nova_bomb":
			Art.shape(ci, Transform2D(0, c) * Art.star(8, s * 0.95, s * 0.4), Art.with_alpha(color, 0.3), color, w)
			ci.draw_circle(c, s * 0.22, color)
		"time_brake":
			ci.draw_arc(c, s * 0.8, 0, TAU, 28, color, w, true)
			ci.draw_line(c, p.call(0, -0.55), color, w * 1.2, true)
			ci.draw_line(c, p.call(0.4, 0.15), color, w * 1.2, true)
		"option_pods":
			# A ship's nose with two glowing pods trailing it.
			ci.draw_colored_polygon(PackedVector2Array([p.call(0, -0.85), p.call(0.3, -0.25), p.call(-0.3, -0.25)]), color)
			ci.draw_circle(p.call(-0.45, 0.25), s * 0.22, color)
			ci.draw_circle(p.call(0.45, 0.55), s * 0.22, color)
		"soul_lantern":
			# A lantern with a wisp flame inside.
			ci.draw_rect(Rect2(p.call(-0.45, -0.45), Vector2(s * 0.9, s * 1.1)), Art.with_alpha(color, 0.25))
			ci.draw_rect(Rect2(p.call(-0.45, -0.45), Vector2(s * 0.9, s * 1.1)), color, false, w)
			ci.draw_line(p.call(0, -0.45), p.call(0, -0.8), color, w)
			ci.draw_colored_polygon(PackedVector2Array([p.call(0, -0.25), p.call(0.22, 0.25), p.call(0, 0.45), p.call(-0.22, 0.25)]), color)
		"ion_cannon":
			# A cannon firing a wide beam.
			ci.draw_rect(Rect2(p.call(-0.85, -0.25), Vector2(s * 0.6, s * 0.5)), color)
			ci.draw_rect(Rect2(p.call(-0.2, -0.15), Vector2(s * 1.05, s * 0.3)), Art.with_alpha(color, 0.6))
			ci.draw_line(p.call(-0.2, 0), p.call(0.85, 0), Color(1, 1, 1, 0.9), w)
		"thruster_explosion":
			# A blast behind a streaking arrowhead.
			ci.draw_colored_polygon(PackedVector2Array([p.call(0.85, 0), p.call(0.1, -0.4), p.call(0.25, 0), p.call(0.1, 0.4)]), color)
			Art.shape(ci, Transform2D(0.0, p.call(-0.45, 0)) * Art.star(7, s * 0.45, s * 0.2), Art.with_alpha(color, 0.5), color, w * 0.6)
		# ---- mission types
		"star_cluster":
			for i in 3:
				var at: Vector2 = p.call(-0.5 + i * 0.5, -0.3 + (i % 2) * 0.5)
				ci.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -s * 0.3), at + Vector2(s * 0.22, s * 0.2), at + Vector2(-s * 0.22, s * 0.2)]), color)
		"corridor":
			ci.draw_line(p.call(-0.7, -0.9), p.call(-0.35, 0.9), color, w * 1.3, true)
			ci.draw_line(p.call(0.7, -0.9), p.call(0.35, 0.9), color, w * 1.3, true)
			ci.draw_colored_polygon(PackedVector2Array([p.call(0, -0.35), p.call(0.2, 0.25), p.call(-0.2, 0.25)]), color)
		"planet":
			ci.draw_circle(c, s * 0.6, Art.with_alpha(color, 0.3))
			ci.draw_arc(c, s * 0.6, 0, TAU, 24, color, w, true)
			ci.draw_arc(c, s * 0.95, 3.5, 6.0, 16, color, w, true)
		"dungeon":
			ci.draw_rect(Rect2(p.call(-0.8, -0.8), Vector2(s * 0.7, s * 0.7)), color, false, w)
			ci.draw_rect(Rect2(p.call(0.1, -0.8), Vector2(s * 0.7, s * 0.7)), color, false, w)
			ci.draw_rect(Rect2(p.call(0.1, 0.1), Vector2(s * 0.7, s * 0.7)), color, false, w)
			ci.draw_line(p.call(-0.1, -0.45), p.call(0.1, -0.45), color, w)
			ci.draw_line(p.call(0.45, -0.1), p.call(0.45, 0.1), color, w)
		# ---- menus and HUD
		"map":
			ci.draw_polyline(PackedVector2Array([p.call(-0.8, 0.5), p.call(-0.2, -0.3), p.call(0.3, 0.2), p.call(0.8, -0.6)]), color, w, true)
			for q in [Vector2(-0.8, 0.5), Vector2(-0.2, -0.3), Vector2(0.3, 0.2), Vector2(0.8, -0.6)]:
				ci.draw_circle(c + q * s, s * 0.15, color)
		"hangar":
			ci.draw_colored_polygon(PackedVector2Array([p.call(0.9, 0), p.call(-0.5, -0.7), p.call(-0.2, 0), p.call(-0.5, 0.7)]), Art.with_alpha(color, 0.35))
			ci.draw_polyline(PackedVector2Array([p.call(0.9, 0), p.call(-0.5, -0.7), p.call(-0.2, 0), p.call(-0.5, 0.7), p.call(0.9, 0)]), color, w, true)
		"guide":
			# An open book.
			for side in [-1.0, 1.0]:
				ci.draw_polyline(PackedVector2Array([p.call(0, -0.55), p.call(0.85 * side, -0.75), p.call(0.85 * side, 0.6), p.call(0, 0.8), p.call(0, -0.55)]), color, w, true)
				for i in 3:
					ci.draw_line(p.call(0.2 * side, -0.35 + i * 0.3), p.call(0.65 * side, -0.45 + i * 0.3), Art.with_alpha(color, 0.6), w * 0.7)
		"lab":
			ci.draw_polyline(PackedVector2Array([p.call(-0.25, -0.8), p.call(-0.25, -0.1), p.call(-0.7, 0.8), p.call(0.7, 0.8), p.call(0.25, -0.1), p.call(0.25, -0.8)]), color, w, true)
			ci.draw_line(p.call(-0.45, 0.35), p.call(0.45, 0.35), color, w)
		"settings":
			ci.draw_arc(c, s * 0.45, 0, TAU, 20, color, w * 1.3, true)
			for i in 8:
				var a := TAU * i / 8.0
				ci.draw_line(c + Vector2.from_angle(a) * s * 0.55, c + Vector2.from_angle(a) * s * 0.9, color, w * 1.6)
		"pause":
			ci.draw_rect(Rect2(p.call(-0.5, -0.6), Vector2(s * 0.35, s * 1.2)), color)
			ci.draw_rect(Rect2(p.call(0.15, -0.6), Vector2(s * 0.35, s * 1.2)), color)
		"lock":
			ci.draw_rect(Rect2(p.call(-0.55, -0.1), Vector2(s * 1.1, s * 0.85)), color)
			ci.draw_arc(p.call(0, -0.1), s * 0.38, PI, TAU, 12, color, w * 1.3)
		"check":
			ci.draw_polyline(PackedVector2Array([p.call(-0.6, 0.0), p.call(-0.15, 0.5), p.call(0.7, -0.5)]), color, w * 1.6, true)
		"blueprint":
			ci.draw_rect(Rect2(p.call(-0.8, -0.6), Vector2(s * 1.6, s * 1.2)), Art.with_alpha(color, 0.25))
			ci.draw_rect(Rect2(p.call(-0.8, -0.6), Vector2(s * 1.6, s * 1.2)), color, false, w)
			for i in 3:
				ci.draw_line(p.call(-0.5, -0.25 + i * 0.25), p.call(0.5 - i * 0.2, -0.25 + i * 0.25), color, w * 0.8)
		"crate":
			ci.draw_rect(Rect2(p.call(-0.7, -0.6), Vector2(s * 1.4, s * 1.2)), Art.with_alpha(color, 0.3))
			ci.draw_rect(Rect2(p.call(-0.7, -0.6), Vector2(s * 1.4, s * 1.2)), color, false, w)
			ci.draw_line(p.call(-0.7, -0.1), p.call(0.7, -0.1), color, w)
		"frame":
			FrameArt.draw_frame(ci, "vanguard", "ship", c, -PI * 0.5, 0.0, {})
		"danger":
			ci.draw_colored_polygon(PackedVector2Array([p.call(0, -0.85), p.call(0.85, 0.7), p.call(-0.85, 0.7)]), Art.with_alpha(color, 0.3))
			ci.draw_polyline(PackedVector2Array([p.call(0, -0.85), p.call(0.85, 0.7), p.call(-0.85, 0.7), p.call(0, -0.85)]), color, w, true)
			ci.draw_line(p.call(0, -0.3), p.call(0, 0.25), color, w * 1.2)
			ci.draw_circle(p.call(0, 0.45), w * 0.7, color)
		"log":
			ci.draw_rect(Rect2(p.call(-0.6, -0.8), Vector2(s * 1.2, s * 1.6)), color, false, w)
			for i in 4:
				ci.draw_line(p.call(-0.35, -0.45 + i * 0.3), p.call(0.35, -0.45 + i * 0.3), color, w * 0.8)
		"repair":
			ci.draw_rect(Rect2(p.call(-0.2, -0.7), Vector2(s * 0.4, s * 1.4)), color)
			ci.draw_rect(Rect2(p.call(-0.7, -0.2), Vector2(s * 1.4, s * 0.4)), color)
		# ---- field upgrades and fusions
		"echo_chamber":
			for i in 3:
				ci.draw_arc(p.call(-0.6, 0), s * (0.4 + i * 0.3), -0.7, 0.7, 12, Art.with_alpha(color, 1.0 - i * 0.25), w, true)
		"vampiric_plating":
			ci.draw_colored_polygon(PackedVector2Array([p.call(0, -0.8), p.call(0.6, -0.3), p.call(0, 0.85), p.call(-0.6, -0.3)]), Art.with_alpha(color, 0.3))
			ci.draw_colored_polygon(PackedVector2Array([p.call(-0.25, -0.2), p.call(-0.12, 0.3), p.call(0, -0.2)]), color)
			ci.draw_colored_polygon(PackedVector2Array([p.call(0.25, -0.2), p.call(0.12, 0.3), p.call(0, -0.2)]), color)
		"last_stand":
			ci.draw_polyline(PackedVector2Array([p.call(-0.6, 0.7), p.call(-0.6, -0.2), p.call(0, -0.8), p.call(0.6, -0.2), p.call(0.6, 0.7)]), color, w * 1.3, true)
			ci.draw_line(p.call(0, -0.3), p.call(0, 0.3), color, w * 1.4)
			ci.draw_circle(p.call(0, 0.55), w * 0.8, color)
		"shrapnel_skin":
			for i in 8:
				var a := TAU * i / 8.0
				ci.draw_line(c + Vector2.from_angle(a) * s * 0.3, c + Vector2.from_angle(a) * s * 0.9, color, w, true)
			ci.draw_circle(c, s * 0.25, Art.with_alpha(color, 0.5))
		"overclocked_servos":
			for i in 3:
				ci.draw_polyline(PackedVector2Array([p.call(-0.7 + i * 0.5, -0.6), p.call(-0.3 + i * 0.5, 0), p.call(-0.7 + i * 0.5, 0.6)]), color, w * 1.3, true)
		"tractor_beam":
			ci.draw_arc(p.call(0, 0.15), s * 0.6, PI, TAU, 14, color, w * 2.0)
			ci.draw_line(p.call(-0.6, 0.15), p.call(-0.6, 0.6), color, w * 2.0)
			ci.draw_line(p.call(0.6, 0.15), p.call(0.6, 0.6), color, w * 2.0)
		"field_repair":
			ci.draw_rect(Rect2(p.call(-0.2, -0.7), Vector2(s * 0.4, s * 1.4)), color)
			ci.draw_rect(Rect2(p.call(-0.7, -0.2), Vector2(s * 1.4, s * 0.4)), color)
		"lucky_salvage":
			Art.shape(ci, Transform2D(0, c) * Art.ngon(4, s * 0.8, PI * 0.25), Art.with_alpha(color, 0.25), color, w)
			draw_text(ci, "7", rect, color)
		"fusion":
			ci.draw_arc(p.call(-0.3, 0), s * 0.55, 0, TAU, 24, color, w * 1.2, true)
			ci.draw_arc(p.call(0.3, 0), s * 0.55, 0, TAU, 24, color, w * 1.2, true)
			ci.draw_circle(c, s * 0.18, color)
		"prize":
			Art.shape(ci, Transform2D(-PI * 0.5, c) * Art.star(5, s * 0.9, s * 0.4), Art.with_alpha(color, 0.4), color, w)
		_:
			# Field upgrades and anything else: a diamond with a dot.
			Art.shape(ci, PackedVector2Array([p.call(0, -0.85), p.call(0.85, 0), p.call(0, 0.85), p.call(-0.85, 0)]), Art.with_alpha(color, 0.25), color, w)
			ci.draw_circle(c, s * 0.2, color)
