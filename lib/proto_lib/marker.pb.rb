## Generated from marker.proto for 
require "beefcake"


class Marker
  include Beefcake::Message

  module Type
    CUSTOM = 0
    TONER = 1
    INK = 2
    STAPLES = 3
  end

  class Color
    include Beefcake::Message

    module Type
      CUSTOM = 0
      BLACK = 1
      COLOR = 2
      CYAN = 3
      MAGENTA = 4
      YELLOW = 5
      LIGHT_CYAN = 6
      LIGHT_MAGENTA = 7
      GRAY = 8
      LIGHT_GRAY = 9
    end
  end
end

class Marker

  class Color
    optional :type, Marker::Color::Type, 1
    optional :custom_display_name, :string, 2
    repeated :custom_display_name_localized, LocalizedString, 3
  end
  optional :vendor_id, :string, 1
  optional :type, Marker::Type, 2
  optional :color, Marker::Color, 3
  optional :custom_display_name, :string, 4
  repeated :custom_display_name_localized, LocalizedString, 5
end
