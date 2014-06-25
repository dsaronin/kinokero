## Generated from dpi.proto for 
require "beefcake"


class Dpi
  include Beefcake::Message

  class Option
    include Beefcake::Message
  end
end

class Dpi

  class Option
    optional :horizontal_dpi, :int32, 1
    optional :vertical_dpi, :int32, 2
    optional :is_default, :bool, 3, :default => false
    optional :custom_display_name, :string, 4
    optional :vendor_id, :string, 5
  end
  repeated :option, Dpi::Option, 1
  optional :min_horizontal_dpi, :int32, 2
  optional :max_horizontal_dpi, :int32, 3
  optional :min_vertical_dpi, :int32, 4
  optional :max_vertical_dpi, :int32, 5
end
