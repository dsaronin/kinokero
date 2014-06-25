## Generated from margins.proto for 
require "beefcake"


class Margins
  include Beefcake::Message

  module Type
    BORDERLESS = 0
    STANDARD = 1
    CUSTOM = 2
  end

  class Option
    include Beefcake::Message
  end
end

class Margins

  class Option
    optional :type, Margins::Type, 1
    optional :top_microns, :int32, 2
    optional :right_microns, :int32, 3
    optional :bottom_microns, :int32, 4
    optional :left_microns, :int32, 5
    optional :is_default, :bool, 6, :default => false
  end
  repeated :option, Margins::Option, 1
end
