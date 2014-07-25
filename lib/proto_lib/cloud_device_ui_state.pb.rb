## Generated from cloud_device_ui_state.proto for 
require "beefcake"


class CloudDeviceUiState
  include Beefcake::Message

  module Summary
    IDLE = 0
    PROCESSING = 1
    STOPPED = 2
    OFFLINE = 3
  end
end

class CloudDeviceUiState
  optional :summary, CloudDeviceUiState::Summary, 1, :default => CloudDeviceUiState::Summary::IDLE
  optional :severity, CloudDeviceUiStateSeverity::Severity, 2, :default => CloudDeviceUiStateSeverity::Severity::NONE
  optional :num_issues, :int32, 3, :default => 0
  optional :caption, :string, 4
  optional :printer, PrinterUiStateSection, 5
end
