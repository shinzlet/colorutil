require "./spec_helper.cr"

include ColorUtil

hash = {
   :bg => Color.from_hex(0xfeba19),
   :red => [0f64, 100f64],
   :green => [180f64, 50f64]
}

palette = Palette.build(hash) do |r, lk|
   r << EqualContrast.new([ lk[:bg], lk[:red] ], 4.5f64)
   r << EqualContrast.new([ lk[:red], lk[:green] ], 3f64)
end

pp palette
puts palette[:bg].contrast(palette[:red])
puts palette[:red].contrast(palette[:green])

set_background(palette[:bg].to_hex_string)
(0..8).each { |idx| set_color(idx, palette[:red].to_hex_string) }
(8..16).each { |idx| set_color(idx, palette[:green].to_hex_string) }
set_special(10, palette[:green].to_hex_string)

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
