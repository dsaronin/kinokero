## Generated from marker_state.proto for 
require "beefcake"


class MarkerState
  include Beefcake::Message

  class Item
    include Beefcake::Message

    module StateType
      OK = 0
      EXHAUSTED = 1
      REMOVED = 2
      FAILURE = 3
    end
  end
end

class MarkerState

  class Item
    optional :vendor_id, :string, 1
    optional :state, MarkerState::Item::StateType, 2
    optional :level_percent, :int32, 3
    optional :level_pages, :int32, 4
    optional :vendor_message, :string, 101
  end
  repeated :item, MarkerState::Item, 1
end
