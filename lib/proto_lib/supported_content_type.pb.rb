## Generated from supported_content_type.proto for 
require "beefcake"


class SupportedContentType
  include Beefcake::Message
end

class SupportedContentType
  optional :content_type, :string, 1
  optional :min_version, :string, 2
  optional :max_version, :string, 3
end
