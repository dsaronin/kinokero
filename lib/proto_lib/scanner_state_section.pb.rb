## Generated from scanner_state_section.proto for 
require "beefcake"


class ScannerStateSection
  include Beefcake::Message

  module StateType
    IDLE = 0
    PROCESSING = 1
    STOPPED = 2
  end
end

class ScannerStateSection
  optional :state, ScannerStateSection::StateType, 1
end
