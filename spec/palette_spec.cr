require "./spec_helper.cr"

include ColorUtil

basis = {
  # :bg => Color.from_hsl(0, 0, ColorUtil.inverse_approx_relative_luminance(1)),
  :bg => Color.from_hex(0x32302f),
  :a => [14.8f64, 98.4f64],
  :b => [56.9f64, 80.1f64]
}

palette = Palette.build(basis) do |r, lk|
  r << EqualContrast.new( [lk[:a], lk[:bg]], 1.5)
  r << EqualContrast.new( [lk[:b], lk[:bg]], 5.5)
  r << EqualContrast.new( [lk[:a], lk[:b]], 2.5)
end

set_background(palette[:bg].to_hex_string)
(0..16).each { |idx| set_color(idx, palette[idx % 2 == 0 ? :a : :b].to_hex_string) }
set_special(10, palette[:a].to_hex_string)

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
