require "./spec_helper.cr"

include ColorUtil

se = SemanticPalette.new(
   Color.from_hsl(150, 100, 50),
   [[255f64, 255f64], [255f64, 255f64]],
   [
     [0f64, 1f64, 2.0],
     [0f64, 2f64, 2.0],
     [1f64, 2f64, 3.0]
   ]
)

pp se
bk = se.bake
pp bk

# fixed = 0.2
# wrt = 0.1
# print BakedPalette.d_contrast(fixed, wrt)
