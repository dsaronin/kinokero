## Generated from cloud_device_state.proto for 
require "beefcake"


class CloudDeviceState
  include Beefcake::Message

  module CloudConnectionStateType
    UNKNOWN = 0
    NOT_CONFIGURED = 1
    ONLINE = 2
    OFFLINE = 3
  end
end

class CloudDeviceState
  optional :version, :string, 1
  optional :cloud_connection_state, CloudDeviceState::CloudConnectionStateType, 2
  optional :printer, PrinterStateSection, 3
  optional :scanner, ScannerStateSection, 4
end
