## Generated from printer_description_section.proto for 
require "beefcake"


class PrinterDescriptionSection
  include Beefcake::Message
end

class PrinterDescriptionSection
  repeated :supported_content_type, SupportedContentType, 1
  optional :printing_speed, PrintingSpeed, 2
  optional :pwg_raster_config, PwgRasterConfig, 3
  repeated :input_tray_unit, InputTrayUnit, 4
  repeated :output_bin_unit, OutputBinUnit, 5
  repeated :marker, Marker, 6
  repeated :cover, Cover, 7
  repeated :media_path, MediaPath, 8
  repeated :vendor_capability, VendorCapability, 101
  optional :color, Color, 102
  optional :duplex, Duplex, 103
  optional :page_orientation, PageOrientation, 104
  optional :copies, Copies, 105
  optional :margins, Margins, 106
  optional :dpi, Dpi, 107
  optional :fit_to_page, FitToPage, 108
  optional :page_range, PageRange, 109
  optional :media_size, MediaSize, 110
  optional :collate, Collate, 111
  optional :reverse_order, ReverseOrder, 112
end
