require "../src/colorutil"
require "ishi"
require "json"

include ColorUtil

def despecify(color)
  h,s,l = color.hsl
  [h, s]
end


def blend_palettes(start, stop, rise)
  bg = Color.mix(Color.from_hex(start["background"].to_s), Color.from_hex(stop["background"].to_s), rise)
  fg = Color.mix(Color.from_hex(start["foreground"].to_s), Color.from_hex(stop["foreground"].to_s), rise)

  basis = {
    :bg => bg,
    :fg => fg
  } of Symbol | Int32 => ColorUtil::Palette::Optimizer::AnyColor

  16.times do |i|
    start_col = Color.from_hex(start["color"][i].to_s)
    stop_col = Color.from_hex(stop["color"][i].to_s)

    basis[i] = despecify Color.mix(start_col, stop_col, rise)
  end

  palette, opt = Palette.build(basis) do |r, lk|
    16.times do |i|
      start_contrast = Color.from_hex(start["color"][i].to_s).contrast(Color.from_hex(start["background"].to_s))
      stop_contrast = Color.from_hex(stop["color"][i].to_s).contrast(Color.from_hex(stop["background"].to_s))

      contrast = stop_contrast * rise + start_contrast * (1 - rise)
      puts contrast
      r << EqualContrast.new( [lk[:bg], lk[i]], contrast )
    end

    # r << EqualContrast.new( [lk[8], lk[2]], 5f64)
  end

	# Ishi.new do
	# 	plot(opt.plotdata)
	# 	show
	# end

	{palette, opt}
end

hund = JSON.parse(File.read("./examples/data/embers.light.txt"))
sweetlove = JSON.parse(File.read("./examples/data/sweetlove.json"))
output = File.open("/dev/pts/4", "w")
steps = 50
iterationdata = Array(Float64).new(initial_capacity: steps)
pal, opt = blend_palettes(hund, sweetlove, 0)
puts ""
16.times do |i|
  # puts pal[i].contrast(Color.from_hex(hund["background"].to_s))
  puts Color.from_hex(hund["color"][i].to_s).rgb
  puts pal[i].rgb
  puts
end
# puts opt.energy
abort

# last_update_error = -1
# stop_updating_threshold = 20
# restart_updating_threshold = 10
steps.times do |iter|
  blend = iter / steps.to_f64
  palette, opt = blend_palettes(hund, sweetlove, blend)

  set_background(palette[:bg].to_hex_string, output)
  set_special(10, palette[:fg].to_hex_string, output)
  16.times { |i| set_color(i, palette[i].to_hex_string, output) }
  output.flush
  sleep 10.milliseconds
	iterationdata << opt.energy
end

Ishi.new do
	plot(iterationdata)
	show
end

def set_special(index, color : String, io : IO = STDOUT)
   io << "\033]#{index};#{color}\033\\"
end

def set_color(index, color : String, io : IO = STDOUT)
  io << "\033]4;#{index};#{color}\033\\"
end

def set_background(color : String, io : IO = STDOUT)
  io << "\033]11;#{color}\033\\" # Sets background
  io << "\033]708;#{color}\033\\" # Sets border color
end
