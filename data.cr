require "./src/colorutil"

include ColorUtil

(0..100).step(2).each do |lum|
	col = Color.from_hsl(0f64, 0f64, lum.to_f64)
	puts "#{col.l},#{col.relative_luminance}"
end
