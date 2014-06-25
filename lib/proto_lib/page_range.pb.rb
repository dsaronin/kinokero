## Generated from page_range.proto for 
require "beefcake"


class PageRange
  include Beefcake::Message

  class Interval
    include Beefcake::Message
  end
end

class PageRange

  class Interval
    optional :start, :int32, 1
    optional :end, :int32, 2
  end
  repeated :default, PageRange::Interval, 1
end
