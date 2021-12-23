require "ishi"
require "../src/colorutil/cmf.cr"

include ColorUtil

lambda = Array.new(CMF::SAMPLE_COUNT) { |idx| CMF::START_NM + idx * CMF::STEP_NM}

Ishi.new do
	plot(lambda, CMF::RED, style: :lines)
	plot(lambda, CMF::GREEN, style: :lines)
	plot(lambda, CMF::BLUE, style: :lines)
end
