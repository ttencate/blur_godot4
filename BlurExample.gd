extends Control

func _ready():
	$%BlurRadiusSlider.value_changed.connect(_blur_changed)
	_blur_changed($%BlurRadiusSlider.value)

func _blur_changed(radius: float):
	$%BlurX.material.set_shader_parameter("radius", radius)
	$%BlurY.material.set_shader_parameter("radius", radius)
	$%BlurRadiusLabel.text = "%.2f" % [radius]
