## Generated from select_capability.proto for 
require "beefcake"


class SelectCapability
  include Beefcake::Message

  class Option
    include Beefcake::Message
  end
end

class SelectCapability

  class Option
    optional :value, :string, 1
    optional :display_name, :string, 2
    optional :is_default, :bool, 3, :default => false
    repeated :display_name_localized, LocalizedString, 4
  end
  repeated :option, SelectCapability::Option, 1
end
