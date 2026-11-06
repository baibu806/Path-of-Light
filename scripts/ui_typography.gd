class_name UITypography
extends RefCounted

const SANS_REGULAR := preload("res://assets/fonts/HarmonyOS_Sans_SC_Regular.ttf")
const SANS_MEDIUM := preload("res://assets/fonts/HarmonyOS_Sans_SC_Medium.ttf")
const SANS_BOLD := preload("res://assets/fonts/HarmonyOS_Sans_SC_Bold.ttf")
const SERIF_DISPLAY := preload("res://assets/fonts/SourceHanSerifSC-SemiBold.otf")
const STORY := preload("res://assets/fonts/LXGWWenKai-Regular.ttf")


static func display(control: Control, size: int) -> void:
	control.add_theme_font_override("font", SERIF_DISPLAY)
	control.add_theme_font_size_override("font_size", size)


static func heading(control: Control, size: int) -> void:
	control.add_theme_font_override("font", SANS_BOLD)
	control.add_theme_font_size_override("font_size", size)


static func body(control: Control, size: int) -> void:
	control.add_theme_font_override("font", SANS_REGULAR)
	control.add_theme_font_size_override("font_size", size)


static func button(control: Control, size: int) -> void:
	control.add_theme_font_override("font", SANS_MEDIUM)
	control.add_theme_font_size_override("font_size", size)


static func story(control: Control, size: int) -> void:
	control.add_theme_font_override("font", STORY)
	control.add_theme_font_size_override("font_size", size)
