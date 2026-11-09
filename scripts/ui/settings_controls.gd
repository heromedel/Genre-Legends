class_name SettingsControls
## The controls that change a setting: a volume slider and an on/off toggle, saved as you change them.
## Shared by the Command Center's Settings page and the pause menu, so both behave the same.


static func slider(label: String, key: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name := UiKit.label(label, 17)
	name.custom_minimum_size = Vector2(180, 0)
	row.add_child(name)
	var bar := HSlider.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.step = 0.05
	bar.value = Save.setting(key)
	bar.custom_minimum_size = Vector2(300, 40)
	bar.value_changed.connect(func(value):
		Save.data["settings"][key] = value
		Sound.refresh_volume())
	bar.drag_ended.connect(func(_changed):
		Save.write()
		PlayLog.note("tap", "%s volume set to %d%%" % [label, int(bar.value * 100)]))
	row.add_child(bar)
	return row


static func toggle(label: String, key: String) -> Control:
	var button := UiKit.button("", func(): pass, "Settings: %s" % label)
	var refresh := func(): button.text = "%s: %s" % [label, "On" if Save.setting(key) else "Off"]
	refresh.call()
	button.pressed.connect(func():
		Save.set_setting(key, not Save.setting(key))
		if key == "fullscreen":
			Browser.set_fullscreen_wanted(Save.setting(key))
			if not Save.setting(key):
				Browser.leave_fullscreen()
		refresh.call())
	return button
