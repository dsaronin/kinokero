## Generated from duplex.proto for 
require "beefcake"


class Duplex
  include Beefcake::Message

  module Type
    NO_DUPLEX = 0
    LONG_EDGE = 1
    SHORT_EDGE = 2
  end

  class Option
    include Beefcake::Message
  end
end

class Duplex

  class Option
    optional :type, Duplex::Type, 1, :default => Duplex::Type::NO_DUPLEX
    optional :is_default, :bool, 2, :default => false
  end
  repeated :option, Duplex::Option, 1
end
