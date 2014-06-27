## Generated from input_tray_unit.proto for 
require "beefcake"


class InputTrayUnit
  include Beefcake::Message

  module Type
    CUSTOM = 0
    INPUT_TRAY = 1
    BYPASS_TRAY = 2
    MANUAL_FEED_TRAY = 3
    LCT = 4
    ENVELOPE_TRAY = 5
    ROLL = 6
  end
end

class InputTrayUnit
  optional :vendor_id, :string, 1
  optional :type, InputTrayUnit::Type, 2
  optional :index, :int64, 3
  optional :custom_display_name, :string, 4
  repeated :custom_display_name_localized, LocalizedString, 5
end
