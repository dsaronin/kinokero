## Generated from page_orientation.proto for 
require "beefcake"


class PageOrientation
  include Beefcake::Message

  module Type
    PORTRAIT = 0
    LANDSCAPE = 1
    AUTO = 2
  end

  class Option
    include Beefcake::Message
  end
end

class PageOrientation

  class Option
    optional :type, PageOrientation::Type, 1
    optional :is_default, :bool, 2, :default => false
  end
  repeated :option, PageOrientation::Option, 1
end
