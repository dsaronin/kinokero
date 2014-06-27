## Generated from pwg_raster_config.proto for 
require "beefcake"


class PwgRasterConfig
  include Beefcake::Message

  module DocumentSheetBack
    NORMAL = 0
    ROTATED = 1
    MANUAL_TUMBLE = 2
    FLIPPED = 3
  end

  module PwgDocumentTypeSupported
    BLACK_1 = 1
    SGRAY_1 = 2
    ADOBE_RGB_8 = 3
    BLACK_8 = 4
    CMYK_8 = 5
    DEVICE1_8 = 6
    DEVICE2_8 = 7
    DEVICE3_8 = 8
    DEVICE4_8 = 9
    DEVICE5_8 = 10
    DEVICE6_8 = 11
    DEVICE7_8 = 12
    DEVICE8_8 = 13
    DEVICE9_8 = 14
    DEVICE10_8 = 15
    DEVICE11_8 = 16
    DEVICE12_8 = 17
    DEVICE13_8 = 18
    DEVICE14_8 = 19
    DEVICE15_8 = 20
    RGB_8 = 21
    SGRAY_8 = 22
    SRGB_8 = 23
    ADOBE_RGB_16 = 24
    BLACK_16 = 25
    CMYK_16 = 26
    DEVICE1_16 = 27
    DEVICE2_16 = 28
    DEVICE3_16 = 29
    DEVICE4_16 = 30
    DEVICE5_16 = 31
    DEVICE6_16 = 32
    DEVICE7_16 = 33
    DEVICE8_16 = 34
    DEVICE9_16 = 35
    DEVICE10_16 = 36
    DEVICE11_16 = 37
    DEVICE12_16 = 38
    DEVICE13_16 = 39
    DEVICE14_16 = 40
    DEVICE15_16 = 41
    RGB_16 = 42
    SGRAY_16 = 43
    SRGB_16 = 44
  end

  class Resolution
    include Beefcake::Message
  end

  class Transformation
    include Beefcake::Message

    module Operation
      ROTATE_180 = 0
      FLIP_ON_LONG_EDGE = 1
      FLIP_ON_SHORT_EDGE = 2
    end

    module Operand
      ALL_PAGES = 0
      ONLY_DUPLEXED_EVEN_PAGES = 1
      ONLY_DUPLEXED_ODD_PAGES = 2
      EVEN_PAGES = 3
      ODD_PAGES = 4
    end
  end
end

class PwgRasterConfig

  class Resolution
    optional :cross_feed_dir, :int32, 1
    optional :feed_dir, :int32, 2
  end

  class Transformation
    optional :operation, PwgRasterConfig::Transformation::Operation, 1
    optional :operand, PwgRasterConfig::Transformation::Operand, 2
    repeated :duplex_type, Duplex::Type, 3
  end
  repeated :document_resolution_supported, PwgRasterConfig::Resolution, 2
  repeated :document_type_supported, PwgRasterConfig::PwgDocumentTypeSupported, 3
  optional :document_sheet_back, PwgRasterConfig::DocumentSheetBack, 4, :default => PwgRasterConfig::DocumentSheetBack::ROTATED
  optional :reverse_order_streaming, :bool, 5
  optional :rotate_all_pages, :bool, 6
  repeated :transformation, PwgRasterConfig::Transformation, 1
end
