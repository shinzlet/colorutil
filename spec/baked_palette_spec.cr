require "./spec_helper.cr"

include ColorUtil

se = SemanticPalette.new()
pp se
bk = se.bake
pp bk

# fixed = 0.2
# wrt = 0.1
# print BakedPalette.d_contrast(fixed, wrt)
