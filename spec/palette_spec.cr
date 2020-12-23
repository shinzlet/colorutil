require "./spec_helper.cr"

include ColorUtil

hash = {
   :bg => Color.from_hex(0xff00ff),
   :red => [0f64, 100f64]
   # :green => [180f64, 100f64]
}

palette = Palette.build(hash) do |r, lk|
   r << EqualContrast.new([lk[:bg], lk[:red]], 3.5f64)
end

pp palette
puts palette[:bg].contrast(palette[:red])
puts palette[:bg].approx_relative_luminance
