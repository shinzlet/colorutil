require "csv"
require "ecr"

# I considered (and am open to) doing this processing with a macro that loads
# the file at compile time, but afaik there's no built in CSV parsing for macros.
# Luckily, I don't really expect the human eye to change much in the next few years :p

# The CMFs are sampled with 390nm <= lambda <= 830nm with a linear spacing of 5nm
# between data points.
START_NM = 390
STEP_NM = 5
STOP_NM = 830
SAMPLE_COUNT = 1 + (STOP_NM - START_NM) // STEP_NM

# The color matching functions are the Stileds & Burch 10-degree RGB CMFs downloaded from
# http://cvrl.ioo.ucl.ac.uk/cmfs.htm, which are bundled with this code in the data folder.
data_dir = (Path[__DIR__] / "../data").normalize
data_file = File.open(data_dir / "sbrgb10w.csv")

cmf_red = Array(Float64).new(SAMPLE_COUNT)
cmf_green = Array(Float64).new(SAMPLE_COUNT)
cmf_blue = Array(Float64).new(SAMPLE_COUNT)

CSV.each_row(data_file) do |row|
	r, g, b = row[1..].map &.to_f64
	cmf_red << r
	cmf_green << g
	cmf_blue << b
end

code = ECR.render("tools/cmf_template.ecr")
File.write("src/colorutil/cmf.cr", code)
