## Generated from range_capability.proto for 
require "beefcake"


class RangeCapability
  include Beefcake::Message

  module ValueType
    FLOAT = 0
    INTEGER = 1
  end
end

class RangeCapability
  optional :value_type, RangeCapability::ValueType, 1
  optional :default, :string, 2
  optional :min, :string, 3
  optional :max, :string, 4
end
