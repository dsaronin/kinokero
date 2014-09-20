## Generated from device_action_cause.proto for 
require "beefcake"


class DeviceActionCause
  include Beefcake::Message

  module ErrorCode
    DOWNLOAD_FAILURE = 0
    INVALID_TICKET = 1
    PRINT_FAILURE = 2
    OTHER = 100
  end
end

class DeviceActionCause
  optional :error_code, DeviceActionCause::ErrorCode, 1
end
