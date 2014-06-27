## Generated from vendor_capability.proto for 
require "beefcake"


class VendorCapability
  include Beefcake::Message

  module Type
    RANGE = 0
    SELECT = 1
    TYPED_VALUE = 2
  end
end

class VendorCapability
  optional :id, :string, 1
  optional :display_name, :string, 2
  optional :type, VendorCapability::Type, 3
  optional :range_cap, RangeCapability, 4
  optional :select_cap, SelectCapability, 5
  optional :typed_value_cap, TypedValueCapability, 6
  repeated :display_name_localized, LocalizedString, 7
end
