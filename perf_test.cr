require "./src/colorutil.cr"

iterations = 1e6
start = Time.utc

(0...iterations).each do
  col = ColorUtil::Color.from_hsl(23, 80, 21)
  col.r
  col.g
  col.b
end

stop = Time.utc

runtime = stop - start

p (runtime.total_nanoseconds / iterations).to_i32
