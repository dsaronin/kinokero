## Generated from output_bin_state.proto for 
require "beefcake"


class OutputBinState
  include Beefcake::Message

  class Item
    include Beefcake::Message

    module StateType
      OK = 0
      FULL = 1
      OPEN = 2
      OFF = 3
      FAILURE = 4
    end
  end
end

class OutputBinState

  class Item
    optional :vendor_id, :string, 1
    optional :state, OutputBinState::Item::StateType, 2
    optional :level_percent, :int32, 3
    optional :vendor_message, :string, 101
  end
  repeated :item, OutputBinState::Item, 1
end
