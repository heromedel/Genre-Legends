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
		"flux_repeater":
			Art.shape(ci, Transform2D(0, c) * Art.ngon(6, s * 0.65), Art.with_alpha(color, 0.25), color, w)
			ci.draw_circle(c, s * 0.2, color)
		"arc_blade":
			# A sword: blade, crossguard and hilt, with a sweep arc behind it.
			ci.draw_arc(c + Vector2(-s * 0.3, s * 0.3), s * 0.95, -PI * 0.5, 0.0, 16, Art.with_alpha(color, 0.45), w, true)
			ci.draw_line(p.call(-0.35, 0.35), p.call(0.75, -0.75), color, w * 1.8, true)
			ci.draw_line(p.call(-0.55, 0.15), p.call(-0.15, 0.55), color, w * 1.4, true)
			ci.draw_line(p.call(-0.35, 0.35), p.call(-0.7, 0.7), color.darkened(0.2), w * 2.2, true)
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
		"shield_generator":
			# A bubble over a small emitter.
			ci.draw_arc(p.call(0, 0.2), s * 0.85, PI * 1.05, TAU - PI * 0.05, 18, color, w * 1.3, true)
			ci.draw_colored_polygon(PackedVector2Array([p.call(-0.35, 0.75), p.call(0.35, 0.75), p.call(0.25, 0.35), p.call(-0.25, 0.35)]), color)
			ci.draw_circle(p.call(0, 0.2), s * 0.18, Color(1, 1, 1, 0.9))
		"dsp1_plate":
			# An armour plate with its rivets.
			var plate := PackedVector2Array([p.call(-0.7, -0.6), p.call(0.7, -0.6), p.call(0.6, 0.7), p.call(-0.6, 0.7)])
			ci.draw_colored_polygon(plate, Art.with_alpha(color, 0.35))
			ci.draw_polyline(plate + PackedVector2Array([plate[0]]), color, w, true)
			for corner in [p.call(-0.45, -0.38), p.call(0.45, -0.38), p.call(-0.4, 0.48), p.call(0.4, 0.48)]:
				ci.draw_circle(corner, w * 0.8, color)
		"qrf_shell", "jig_weave_plate", "lunarium_plate", "mirrorwork_plate", "crusher_plate", "arc_lined_plate", "jig_phase_plate", "last_legend_plate":
			_draw_plate(ci, icon, c, s, w, color)
		"coolant_loop":
			# A coolant pipe looping round a frost crystal.
			ci.draw_arc(c, s * 0.75, PI * 0.15, TAU - PI * 0.15, 22, color, w * 1.4, true)
			for i in 3:
				var a := PI * i / 3.0
				ci.draw_line(c + Vector2.from_angle(a) * s * 0.4, c - Vector2.from_angle(a) * s * 0.4, color, w, true)
		"aux_generator":
			# A generator housing with a power bolt.
			Art.shape(ci, Transform2D(0, c) * Art.ngon(6, s * 0.85, PI / 6.0), Art.with_alpha(color, 0.25), color, w)
			ci.draw_colored_polygon(PackedVector2Array([p.call(0.1, -0.6), p.call(-0.3, 0.1), p.call(0.0, 0.1), p.call(-0.1, 0.6), p.call(0.3, -0.1), p.call(0.0, -0.1)]), color)
		"frame_blueprint":
			# A blueprint sheet with a frame's outline on it.
			var sheet := Rect2(p.call(-0.75, -0.85), Vector2(s * 1.5, s * 1.7))
			ci.draw_rect(sheet, Color(0.15, 0.3, 0.55, 0.8))
			ci.draw_rect(sheet, color, false, w)
			ci.draw_polyline(PackedVector2Array([p.call(0, -0.55), p.call(0.4, 0.35), p.call(0, 0.15), p.call(-0.4, 0.35), p.call(0, -0.55)]), color, w, true)
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
		"mawjig_siphon":
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
		"juggernaut_servos":
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
		"crystal":
			# A Mawjig Crystal: a tall faceted shard with a bright core line.
			var shard := PackedVector2Array([p.call(0, -0.95), p.call(0.5, -0.3), p.call(0.35, 0.75), p.call(0, 0.95), p.call(-0.35, 0.75), p.call(-0.5, -0.3)])
			ci.draw_colored_polygon(shard, Art.with_alpha(color, 0.45))
			ci.draw_colored_polygon(PackedVector2Array([p.call(0, -0.95), p.call(0.5, -0.3), p.call(0, 0.1), p.call(-0.5, -0.3)]), Art.with_alpha(Color(1, 1, 1), 0.35))
			ci.draw_polyline(shard + PackedVector2Array([shard[0]]), color, w, true)
			ci.draw_line(p.call(0, -0.6), p.call(0, 0.7), Color(1, 1, 1, 0.8), w * 0.6, true)
		"wreck_gunship", "wreck_carrier", "wreck_research", "wreck_freighter":
			_draw_wreck(ci, icon, c, s, w, color)
		"depot":
			# A supply drop: a crate under a parachute.
			ci.draw_arc(p.call(0, -0.2), s * 0.75, PI, TAU, 16, color, w * 1.2, true)
			for x in [-0.7, 0.0, 0.7]:
				ci.draw_line(p.call(x, -0.2), p.call(0, 0.3), color, w * 0.7, true)
			ci.draw_rect(Rect2(p.call(-0.35, 0.3), Vector2(s * 0.7, s * 0.6)), color)
		"prize":
			Art.shape(ci, Transform2D(-PI * 0.5, c) * Art.star(5, s * 0.9, s * 0.4), Art.with_alpha(color, 0.4), color, w)
		_:
			# Field upgrades and anything else: a diamond with a dot.
			Art.shape(ci, PackedVector2Array([p.call(0, -0.85), p.call(0.85, 0), p.call(0, 0.85), p.call(-0.85, 0)]), Art.with_alpha(color, 0.25), color, w)
			ci.draw_circle(c, s * 0.2, color)


## The plates share an armour-plate outline; each adds the mark that says what it does.
static func _draw_plate(ci: CanvasItem, plate_id: String, c: Vector2, s: float, w: float, color: Color) -> void:
	var p := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * s
	var outline := PackedVector2Array([p.call(-0.7, -0.6), p.call(0.7, -0.6), p.call(0.6, 0.7), p.call(-0.6, 0.7)])
	if plate_id == "jig_phase_plate":
		# A ghost of the plate, half a step out of this dimension.
		var ghost := outline.duplicate()
		for i in ghost.size():
			ghost[i] += Vector2(s * 0.22, -s * 0.18)
		ci.draw_polyline(ghost + PackedVector2Array([ghost[0]]), Art.with_alpha(color, 0.45), w, true)
	ci.draw_colored_polygon(outline, Art.with_alpha(color, 0.3))
	ci.draw_polyline(outline + PackedVector2Array([outline[0]]), color, w * (1.8 if plate_id == "lunarium_plate" else 1.0), true)
	match plate_id:
		"qrf_shell":
			for i in 3:
				ci.draw_line(p.call(-0.45 + i * 0.3, 0.35), p.call(-0.2 + i * 0.3, -0.35), color, w, true)
		"jig_weave_plate":
			for i in 4:
				var t := -0.45 + i * 0.3
				ci.draw_line(p.call(t, -0.45), p.call(t + 0.2, 0.55), Art.with_alpha(color, 0.8), w * 0.7, true)
				ci.draw_line(p.call(-0.5, t + 0.05), p.call(0.5, t + 0.15), Art.with_alpha(color, 0.8), w * 0.7, true)
		"lunarium_plate":
			ci.draw_arc(c, s * 0.35, PI * 0.6, PI * 1.9, 14, color, w * 1.4, true)
		"mirrorwork_plate":
			ci.draw_colored_polygon(PackedVector2Array([p.call(0.0, -0.6), p.call(0.7, -0.6), p.call(0.6, 0.7), p.call(0.0, 0.7)]), Art.with_alpha(Color(1, 1, 1), 0.45))
			ci.draw_line(p.call(-0.4, 0.4), p.call(0.4, -0.4), Color(1, 1, 1, 0.9), w, true)
		"crusher_plate":
			for x in [-0.3, 0.3]:
				ci.draw_line(p.call(x, -0.4), p.call(x, 0.25), color, w * 1.3, true)
				ci.draw_colored_polygon(PackedVector2Array([p.call(x - 0.18, 0.2), p.call(x + 0.18, 0.2), p.call(x, 0.5)]), color)
		"arc_lined_plate":
			ci.draw_polyline(PackedVector2Array([p.call(-0.5, 0), p.call(-0.25, -0.3), p.call(0, 0.25), p.call(0.25, -0.3), p.call(0.5, 0)]), Color(0.6, 0.95, 1.0), w * 1.2, true)
		"jig_phase_plate":
			ci.draw_arc(c, s * 0.3, 0, TAU, 16, color, w, true)
		"last_legend_plate":
			Art.shape(ci, Transform2D(-PI * 0.5, c) * Art.star(5, s * 0.45, s * 0.2), Art.with_alpha(color, 0.6), color, w * 0.8)



## A derelict on the scanner: a broken hull in the shape of what it was, split by a jagged crack.
static func _draw_wreck(ci: CanvasItem, kind: String, c: Vector2, s: float, w: float, color: Color) -> void:
	var p := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * s
	var hull: PackedVector2Array
	match kind:
		"wreck_gunship":
			hull = PackedVector2Array([p.call(0.9, 0), p.call(0.2, -0.35), p.call(-0.2, -0.75), p.call(-0.5, -0.3), p.call(-0.85, -0.2), p.call(-0.85, 0.2), p.call(-0.5, 0.3), p.call(-0.2, 0.75), p.call(0.2, 0.35)])
		"wreck_carrier":
			hull = PackedVector2Array([p.call(0.9, -0.3), p.call(0.9, 0.3), p.call(-0.9, 0.45), p.call(-0.9, -0.45)])
		"wreck_research":
			hull = PackedVector2Array([p.call(0.6, 0), p.call(0.3, -0.5), p.call(-0.3, -0.5), p.call(-0.6, 0), p.call(-0.3, 0.5), p.call(0.3, 0.5)])
		_:
			hull = PackedVector2Array([p.call(0.85, -0.4), p.call(0.85, 0.4), p.call(-0.85, 0.4), p.call(-0.85, -0.4)])
	ci.draw_colored_polygon(hull, Art.with_alpha(color, 0.3))
	ci.draw_polyline(hull + PackedVector2Array([hull[0]]), color, w, true)
	if kind == "wreck_research":
		ci.draw_arc(c, s * 0.85, -0.6, 0.6, 10, color, w * 0.8, true)
	elif kind == "wreck_carrier":
		for x in [-0.5, 0.0, 0.5]:
			ci.draw_line(p.call(x, -0.35), p.call(x, 0.35), Art.with_alpha(color, 0.6), w * 0.7, true)
	elif kind == "wreck_freighter":
		ci.draw_rect(Rect2(p.call(-0.6, -0.25), Vector2(s * 0.5, s * 0.5)), Art.with_alpha(color, 0.6))
		ci.draw_rect(Rect2(p.call(0.1, -0.25), Vector2(s * 0.5, s * 0.5)), Art.with_alpha(color, 0.6))
	# The crack that made it a wreck.
	ci.draw_polyline(PackedVector2Array([p.call(0.1, -0.8), p.call(-0.05, -0.2), p.call(0.15, 0.1), p.call(-0.1, 0.8)]), Color(0.02, 0.03, 0.06), w * 1.6, true)
