require "kinokero/version"
require "kinokero/ruby_extensions"

module Kinokero
# #########################################################################

  class Cloudprint

# #########################################################################
    # default options and configurations for AntEngine
  DEFAULT_OPTIONS = {
    :cp_url => 'default'
  }
    # will be used to determine if user options valid
    # if (in future) any default options were to be off-limits,
    # then a specific sets of keys will have to be enumerated below 
  VALID_CLOUDPRINT_OPTIONS = DEFAULT_OPTIONS.keys

# #########################################################################


# #########################################################################




# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
  def initialize( options )
    @options = DEFAULT_OPTIONS.merge(options)
    validate_cloudprint_options(@options)
  end
# ------------------------------------------------------------------------------
# validate_cloudprint_options -- validates user's options
# raises exception if invalid
# ------------------------------------------------------------------------------
  def validate_cloudprint_options(options)
# init stuff goes here; options validations;
    options.assert_valid_keys(VALID_CLOUDPRINT_OPTIONS)

#    unless (options[:duty_group_count].nil?
#      raise ArgumentError,":duty_group_count must be > 0"
#    end
    
  end

# #########################################################################
  end  # class Cloudprint

# #########################################################################
end  # module Kinokero
