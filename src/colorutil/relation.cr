module ColorUtil
  struct Relation(T)
    enum Types
      CONTRAST_EQ
    end

    def initialize(@type : Types, @a : T, @b : T, @value : Float64)
    end
    
    def self.contrast_eq(a : T, b : T, value : Float64)
      self.new(Types::CONTRAST_EQ, a, b, value)
    end
  end
end
