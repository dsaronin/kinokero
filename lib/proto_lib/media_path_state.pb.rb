## Generated from media_path_state.proto for 
require "beefcake"


class MediaPathState
  include Beefcake::Message

  class Item
    include Beefcake::Message

    module StateType
      OK = 0
      MEDIA_JAM = 1
      FAILURE = 2
    end
  end
end

class MediaPathState

  class Item
    optional :vendor_id, :string, 1
    optional :state, MediaPathState::Item::StateType, 2
    optional :vendor_message, :string, 101
  end
  repeated :item, MediaPathState::Item, 1
end
