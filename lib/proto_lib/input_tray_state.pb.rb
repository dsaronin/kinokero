## Generated from input_tray_state.proto for 
require "beefcake"


class InputTrayState
  include Beefcake::Message

  class Item
    include Beefcake::Message

    module StateType
      OK = 0
      EMPTY = 1
      OPEN = 2
      OFF = 3
      FAILURE = 4
    end
  end
end

class InputTrayState

  class Item
    optional :vendor_id, :string, 1
    optional :state, InputTrayState::Item::StateType, 2
    optional :level_percent, :int32, 3
    optional :vendor_message, :string, 101
  end
  repeated :item, InputTrayState::Item, 1
end
