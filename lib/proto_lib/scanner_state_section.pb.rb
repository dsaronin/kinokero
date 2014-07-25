## Generated from scanner_state_section.proto for 
require "beefcake"


class ScannerStateSection
  include Beefcake::Message
end

class ScannerStateSection
  optional :state, CloudDeviceStateType::StateType, 1
end
