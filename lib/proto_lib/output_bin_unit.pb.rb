## Generated from output_bin_unit.proto for 
require "beefcake"


class OutputBinUnit
  include Beefcake::Message

  module Type
    CUSTOM = 0
    OUTPUT_BIN = 1
    MAILBOX = 2
    STACKER = 3
  end
end

class OutputBinUnit
  optional :vendor_id, :string, 1
  optional :type, OutputBinUnit::Type, 2
  optional :index, :int64, 3
  optional :custom_display_name, :string, 4
  repeated :custom_display_name_localized, LocalizedString, 5
end
