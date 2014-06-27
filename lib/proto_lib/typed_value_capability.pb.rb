## Generated from typed_value_capability.proto for 
require "beefcake"


class TypedValueCapability
  include Beefcake::Message

  module ValueType
    BOOLEAN = 0
    FLOAT = 1
    INTEGER = 2
    STRING = 3
  end
end

class TypedValueCapability
  optional :value_type, TypedValueCapability::ValueType, 1
  optional :default, :string, 2
end
