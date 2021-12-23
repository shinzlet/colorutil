require "../ishi"

module Ishi
  # Renders chart as PNG.
  #
  class Png < Term
    def initialize(io : IO = STDOUT)
      super("pngcairo enhanced", io)
    end
  end

  class Gnuplot
    def show(chart, **options)
      IO.copy(previous_def(chart), @term.io)
    end

    def show(chart, rows, cols, **options)
      IO.copy(previous_def(chart, rows, cols), @term.io)
    end
  end

  @@default = Png
end
