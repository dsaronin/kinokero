## Generated from printing_speed.proto for 
require "beefcake"


class PrintingSpeed
  include Beefcake::Message

  class Option
    include Beefcake::Message
  end
end

class PrintingSpeed

  class Option
    optional :speed_ppm, :float, 1
    repeated :color_type, Color::Type, 2
    repeated :media_size_name, MediaSize::Name, 3
  end
  repeated :option, PrintingSpeed::Option, 1
end
