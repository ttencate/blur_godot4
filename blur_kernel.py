#!/usr/bin/env python3

import math
import sys

radius = float(sys.argv[1])
size = 1 + 2 * math.ceil(radius)

# Determine mean and standard deviation.
sigma_range = 2.0
mu = float(size // 2)
sigma = radius / sigma_range

# Compute derivative of normal distribution.
xs = [
    float(i - mu)
    for i in range(size)
]
raw_weights = [
    math.exp(-0.5 * (x / sigma)**2)
    for x in xs
]

sum_weight = sum(raw_weights)
weights = [w / sum_weight for w in raw_weights]

# Reduce the number of texture samples by abusing linear interpolation.
sample_xs = [xs[0]]
sample_weights = [weights[0]]
for i in range(1, size, 2):
    x0 = xs[i]
    x1 = xs[i + 1]
    w0 = weights[i]
    w1 = weights[i + 1]
    wsum = w0 + w1
    sample_xs.append(
        w0 / wsum * x0 +
        w1 / wsum * x1
    )
    sample_weights.append(wsum)

# Generate shader code.
samples = [
    f'{w:.9f} * texture(TEXTURE, UV {"+" if x >= 0 else "-"} {abs(x):.9f} * s).rgb'
    for x, w in zip(sample_xs, sample_weights)
]
print('shader_type canvas_item;')
print()
print('// Radius that the shader was designed for.')
print(f'const float DEFAULT_RADIUS = {radius:f};')
print()
print('// Unit vector: (1, 0) or (0, 1)')
print('uniform vec2 step;')
print('// Desired blur radius.')
print(f'uniform float radius = {radius:f};')
print()
print('void fragment() {')
print(f'\tvec2 s = radius / DEFAULT_RADIUS * step / vec2(textureSize(TEXTURE, 0));')
print('\tCOLOR.rgb =')
print('\t\t' + ' +\n\t\t'.join(samples) + ';');
print('\tCOLOR.a = 1.0;')
print('}')
