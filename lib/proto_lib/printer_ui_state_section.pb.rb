## Generated from printer_ui_state_section.proto for 
require "beefcake"


class PrinterUiStateSection
  include Beefcake::Message

  class Item
    include Beefcake::Message
  end
end

class PrinterUiStateSection

  class Item
    optional :severity, CloudDeviceUiStateSeverity::Severity, 1
    optional :message, :string, 2
    optional :vendor_message, :string, 3
    optional :level_percent, :int32, 4
    optional :color, Marker::Color::Type, 5
  end
  repeated :vendor_item, PrinterUiStateSection::Item, 1
  repeated :input_tray_item, PrinterUiStateSection::Item, 2
  repeated :output_bin_item, PrinterUiStateSection::Item, 3
  repeated :marker_item, PrinterUiStateSection::Item, 4
  repeated :cover_item, PrinterUiStateSection::Item, 5
  repeated :media_path_item, PrinterUiStateSection::Item, 6
end
