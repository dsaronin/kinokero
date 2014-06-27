## Generated from cover.proto for 
require "beefcake"


class Cover
  include Beefcake::Message

  module Type
    CUSTOM = 0
    DOOR = 1
    COVER = 2
  end
end

class Cover
  optional :vendor_id, :string, 1
  optional :type, Cover::Type, 2
  optional :index, :int64, 3
  optional :custom_display_name, :string, 4
  repeated :custom_display_name_localized, LocalizedString, 5
end
