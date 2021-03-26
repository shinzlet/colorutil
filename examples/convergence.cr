require "ishi"
require "../src/colorutil"

include ColorUtil

basis = {
	:fixed => Color.from_hex(0x0000000),
	:free => [0f64, 0f64]
}

lk, _ = Palette.create_lookup(basis)

relations = [
	Relations::EqualContrast.new([lk[:fixed], lk[:free]], 3.5f64)
] of Relations::Relation

opt = Palette::Optimizer.new(lk, relations)

(0..10).each do 
	opt.step_gd(0.005)
end

Ishi.new do
	plot(opt.plotdata)
	show
end
