## Generated from cover_state.proto for 
require "beefcake"


class CoverState
  include Beefcake::Message

  class Item
    include Beefcake::Message

    module StateType
      OK = 0
      OPEN = 1
      FAILURE = 2
    end
  end
end

class CoverState

  class Item
    optional :vendor_id, :string, 1
    optional :state, CoverState::Item::StateType, 2
    optional :vendor_message, :string, 101
  end
  repeated :item, CoverState::Item, 1
end
