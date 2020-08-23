require "./spec_helper"

include ColorUtil

describe Color do
  describe "#from_hex" do
    it "constructs a color from hex" do
      col = Color.from_hex(0xabcdef)
      col.r.should eq 0xab
      col.g.should eq 0xcd
      col.b.should eq 0xef
    end

    it "raises on overflow" do
      expect_raises(OverflowError) do
        col = Color.from_hex(0xffffff + 1)
      end
    end

    it "doesn't raise for normal colors" do
      Color.from_hex(0xffffff)
      Color.from_hex(0x000000)
    end
  end

  describe "#to_hex" do
    it "is the inverse of #from_hex" do
      col1 = Color.from_hex(0xabcdef)
      col2 = Color.from_hex(col1.to_hex)

      col1.should eq col2
    end
  end

  describe "#==" do
    it "correctly tests for color equality" do
      col1 = Color.from_hex(0xff00ff)
      col2 = Color.from_rgb(255, 0, 255)

      col1.should eq col2
    end
  end

  describe "#to_hex_string" do
    it "correctly converts a color to hex" do
      col = Color.from_hex(0xabcdef)
      col.to_hex_string.should eq "#abcdef"
    end

    it "correctly pads a hex code with zeros" do
      col = Color.from_hex(0xf)
      col.to_hex_string.should eq "#00000f"
    end
  end
end
