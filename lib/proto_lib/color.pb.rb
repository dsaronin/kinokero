## Generated from color.proto for 
require "beefcake"


class Color
  include Beefcake::Message

  module Type
    STANDARD_COLOR = 0
    STANDARD_MONOCHROME = 1
    CUSTOM_COLOR = 2
    CUSTOM_MONOCHROME = 3
    AUTO = 4
  end

  class Option
    include Beefcake::Message
  end
end

class Color

  class Option
    optional :vendor_id, :string, 1
    optional :type, Color::Type, 2
    optional :custom_display_name, :string, 3
    optional :is_default, :bool, 4, :default => false
    repeated :custom_display_name_localized, LocalizedString, 5
  end
  repeated :option, Color::Option, 1
end
