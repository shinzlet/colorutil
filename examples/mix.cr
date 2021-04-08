require "../src/colorutil"
require "ishi"
require "json"

include ColorUtil

# palette processing
def read_palette(filename) : Hash(String, Color)
  raw = JSON.parse(File.read(filename))
  codes = {} of String => JSON::Any

  {"background", "foreground"}.each do |key|
    codes[key] = raw[key]
  end

  (0..15).each do |idx|
    codes[idx.to_s] = raw["color"][idx]
  end

  codes.transform_values { |code| Color.from_hex(code.to_s) }
end

# Converts the saturation and hue of two colors into cartesian, blends them
# there, and then converts back to hue and saturation. This makes interpolation
# from a color to its compliment go throught white, rather than around the color
# wheel.
def mix_chroma(start, stop, rise)
  torad = Math::PI / 180
  x1, y1 = start.s * Math.cos(torad * start.h), start.s * Math.sin(torad * start.h)
  x2, y2 = stop.s * Math.cos(torad * stop.h), stop.s * Math.sin(torad * stop.h)
  xm, ym = x1 + (x2 - x1) * rise, y1 + (y2 - y1) * rise

  [Math.atan2(ym, xm) / torad, Math.hypot(xm, ym)]
end

def blend_palettes(start, stop, rise)
  start_bg = start["background"]
  stop_bg = stop["background"]
  
  basis = {} of String => ColorUtil::Palette::Optimizer::AnyColor
  basis["background"] = Color.mix(start_bg, stop_bg, rise)
  basis["foreground"] = mix_chroma(start["foreground"], stop["foreground"], rise)

  (0..15).each do |idx|
    basis[idx.to_s] = mix_chroma(start[idx.to_s], stop[idx.to_s], rise)
  end

  lk, _ = Palette.create_lookup(basis)
  rel = [] of Relations::Relation

  (0..15).each do |idx|
    start_contrast = start_bg.contrast(start[idx.to_s])
    stop_contrast = stop_bg.contrast(stop[idx.to_s])
    contrast = start_contrast + rise * (stop_contrast - start_contrast)

    rel << Relations::EqualContrast.new( [lk["background"], lk[idx.to_s]], contrast )
  end

  {basis, lk, rel}
end

# color output
def set_special(index, color : String, io : IO = STDOUT)
   io << "\033]#{index};#{color}\033\\"
end

def set_color(index, color : String, io : IO = STDOUT)
  io << "\033]4;#{index};#{color}\033\\"
end

def set_background(color : String, io : IO = STDOUT) set_special(11, color, io) # background color
  set_special(708, color, io) # border color
end

def set_foreground(color : String, io : IO = STDOUT)
  set_special(10, color, io) # foreground color
end

def apply_palette(palette, target = STDOUT)
  set_background(palette["background"].to_hex_string, target)
  set_foreground(palette["foreground"].to_hex_string, target)

  (0..15).each do |idx|
    set_color(idx, palette[idx.to_s].to_hex_string, target)
  end
end

sweetlove = read_palette("./examples/data/sweetlove.json")
monokai = read_palette("./examples/data/monokai.json")
embers_dark = read_palette("./examples/data/embers.dark.txt")
embers_light = read_palette("./examples/data/embers.light.txt")
mocha_dark = read_palette("./examples/data/mocha.dark.txt")
mocha_light = read_palette("./examples/data/mocha.light.txt")

# data = [] of Float64
# pal = 1
# datasize = 1000
# 
# datasize.times do |idx|
#   basis, lk, rel = blend_palettes(embers_light, sweetlove, 0)
# 
#   opt = Palette::Optimizer.new(lk, rel)
#   opt.iteration_target = idx * 10
#   # opt.neighbour_coefficient = 1.5f64 * 0.35 # 1.5f64 / datasize * idx
#   
#   # Optimize
#   opt.optimize
# 
#   data << opt.energy
# 
#   # palette, _ = bundle(basis, lk, opt.lightness, opt)
# end
# 
# Ishi.new do
#   plot(data)
#   show
# end
# puts data.sum / data.size

steps = 100
energy = Array(Float64).new(steps)
target = File.open("/dev/pts/4", "w")
prev = nil

(0..steps).each do |idx|
  basis, lk, rel = blend_palettes(embers_dark, monokai, idx / (steps - 1))

  opt = Palette::Optimizer.new(lk, rel, prev)
  opt.iteration_target = 8000
  opt.exploration_period = 1500
  opt.optimize
  pal, _ = Palette.bundle(basis, lk, opt.lightness, opt)

  prev = opt.lightness
  energy << opt.energy
  apply_palette(pal, target)
end

Ishi.new do
  plot(energy)
  show
end
