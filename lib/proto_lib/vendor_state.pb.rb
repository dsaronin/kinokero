## Generated from vendor_state.proto for 
require "beefcake"


class VendorState
  include Beefcake::Message

  class Item
    include Beefcake::Message

    module StateType
      ERROR = 0
      WARNING = 1
      INFO = 2
    end
  end
end

class VendorState

  class Item
    optional :state, VendorState::Item::StateType, 1
    optional :description, :string, 2
    repeated :description_localized, LocalizedString, 3
  end
  repeated :item, VendorState::Item, 1
end
