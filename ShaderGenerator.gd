@tool
extends EditorScript

# Adjust the constants below according to your needs.
# Then run the script using File > Run.

const RADIUS := 10.0 # Radius of blur kernel.
const SIGMA_RANGE := 2.0 # How many standard deviations fit inside the radius.
const OUTPUT_FILE := "res://Blur.gdshader" # Name of output file to write.

func _run():
	var size := 1 + 2 * ceili(RADIUS)
	
	# Determine mean and standard deviation.
	var mu := float(size / 2)
	var sigma := RADIUS / SIGMA_RANGE
	
	# Compute normal distribution.
	var xs := range(size).map(func(i: int): return i - mu)
	var unscaled_weights := xs.map(func(x: float): return exp(-0.5 * pow(x / sigma, 2.0)))
	var sum_weights: float = unscaled_weights.reduce(func(w1: float, w2: float): return w1 + w2)
	var weights := unscaled_weights.map(func(w: float): return w / sum_weights)
	
	# Print sample points and weights.
	print("Sample weights before linear filtering:")
	print("%13s  %13s" % ["x", "weight"])
	for i in range(len(xs)):
		print("%13+.9f  %13.9f" % [xs[i], weights[i]])
	
	# Reduce the number of texture samples by abusing linear filtering.
	var sample_xs := [xs[0]]
	var sample_weights := [weights[0]]
	for i in range(1, size, 2):
		var x0: float = xs[i]
		var x1: float = xs[i + 1]
		var w0: float = weights[i]
		var w1: float = weights[i + 1]
		var wsum = w0 + w1
		sample_xs.push_back(
			w0 / wsum * x0 +
			w1 / wsum * x1
		)
		sample_weights.push_back(wsum)
	
	# Generate shader code.
	var samples := []
	for i in range(len(sample_xs)):
		var x: float = sample_xs[i]
		var w: float = sample_weights[i]
		samples.push_back('%.9f * texture(TEXTURE, UV %s %.9f * s).rgb' % [
			w, "+" if x >= 0 else "-", abs(x)
		])
	var lines = [
		"shader_type canvas_item;",
		"",
		"// Radius that the shader was designed for.",
		"const float DEFAULT_RADIUS = %.9f;" % [RADIUS],
		"",
		"// Unit vector: (1, 0) or (0, 1)",
		"uniform vec2 step;",
		"// Desired blur radius.",
		"uniform float radius = %.9f;" % [RADIUS],
		"",
		"void fragment() {",
		"\tvec2 s = radius / DEFAULT_RADIUS * step / vec2(textureSize(TEXTURE, 0));",
		"\tCOLOR.rgb =",
		"\t\t" + " +\n\t\t".join(samples) + ";",
		"\tCOLOR.a = 1.0;",
		"}",
	]
	var shader := "\n".join(lines)
	
	print()
	print("Shader code:")
	print(shader)
	
	var file := FileAccess.open(OUTPUT_FILE, FileAccess.WRITE)
	file.store_string(shader + "\n")
	file.close()
	
	print()
	print("Shader code written to %s" % [OUTPUT_FILE])
