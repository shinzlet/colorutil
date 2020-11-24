require "colorutil"

initalize my app


XRESOURCES_COLORS = [:black, :brblack, :red, :brred]

rules = PaletteRules.new(keys: XRESOURCES_COLORS)
rules = PaletteRules.single_bg(keys: XRESOUCRES_COLORS, bg: :black)
rules = PaletteRules.

rules << Rule.contrast_equal(:black, :brblack, 3.5)
rules << Rule.lightness_equal(:black, 2.0)

PaletteRules
PaletteBuilder

Palette

rules = [] of Color::Rule
rules << Color::Rule.contrast_target(:black, :red, 10)

rules = Mood::Color

palette = PaletteBuilder.new(hash, rules)

# hash : Hash(T, Mood::Color | NamedTuple(h: Float64, s: Float64) | Tuple(Float64, Float64)
palette = Mood::Palette.new(hash, rules)

# yields Mood::Rule
palette = Mood::Palette.solve(hash) do |rules|
	rules << contrast_eq(:a, :b, 3.5)
	rules << contrast_gt(:a, :b, 3.5)
end

Rule.contrast_eq(:a, :b, 3.5)

op = Mood::Palette::Optimizer(hash, rules)


Mood.create_palette(hash) do |rules|
	rules << contras
end

Mood.create_palette(hash, rules)

Mood::Palette.new(hash) do |rules|
end

Mood::Palette.create
Mood::Palette::Optimizer
Mood::Palette::Rule
Mood::Palette::
