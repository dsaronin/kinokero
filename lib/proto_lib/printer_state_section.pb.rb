## Generated from printer_state_section.proto for 
require "beefcake"


class PrinterStateSection
  include Beefcake::Message
end

class PrinterStateSection
  optional :state, CloudDeviceStateType::StateType, 1
  optional :input_tray_state, InputTrayState, 2
  optional :output_bin_state, OutputBinState, 3
  optional :marker_state, MarkerState, 4
  optional :cover_state, CoverState, 5
  optional :media_path_state, MediaPathState, 6
  optional :vendor_state, VendorState, 101
end
