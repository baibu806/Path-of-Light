extends Control

const ANIMATIONS := [
	&"idle_front", &"idle_side", &"idle_back",
	&"walk_front", &"walk_side", &"walk_back",
	&"interact_front", &"interact_side", &"interact_back",
	&"repair_front", &"repair_side", &"repair_back",
	&"manual_front", &"manual_side", &"manual_back",
	&"success_front", &"failure_front",
]

@onready var character: AnimatedSprite2D = $Character
@onready var animation_label: Label = $AnimationName
@onready var direction_label: Label = $InfoPanel/Instructions

var current_animation := 0


func _ready() -> void:
	_show_animation()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	match event.keycode:
		KEY_LEFT, KEY_A:
			current_animation = wrapi(current_animation - 1, 0, ANIMATIONS.size())
			_show_animation()
		KEY_RIGHT, KEY_D:
			current_animation = wrapi(current_animation + 1, 0, ANIMATIONS.size())
			_show_animation()
		KEY_SPACE:
			character.play(ANIMATIONS[current_animation])
		KEY_F:
			character.flip_h = not character.flip_h
			_update_instruction()


func _show_animation() -> void:
	var animation_name: StringName = ANIMATIONS[current_animation]
	character.play(animation_name)
	animation_label.text = "%s　（%d / %d）" % [animation_name, current_animation + 1, ANIMATIONS.size()]
	_update_instruction()


func _update_instruction() -> void:
	direction_label.text = "← / → 或 A / D 切换　　空格重播　　F 水平翻转：%s" % ("开启" if character.flip_h else "关闭")

