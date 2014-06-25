## Generated from fit_to_page.proto for 
require "beefcake"


class FitToPage
  include Beefcake::Message

  module Type
    NO_FITTING = 0
    FIT_TO_PAGE = 1
    GROW_TO_PAGE = 2
    SHRINK_TO_PAGE = 3
    FILL_PAGE = 4
  end

  class Option
    include Beefcake::Message
  end
end

class FitToPage

  class Option
    optional :type, FitToPage::Type, 1
    optional :is_default, :bool, 2, :default => false
  end
  repeated :option, FitToPage::Option, 1
end
