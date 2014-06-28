require "kinokero/version"
require "kinokero/ruby_extensions"
require 'faraday-cookie_jar'
require 'logger'
require 'forwardable'

require "faraday"
require "faraday_middleware"
require "simple_oauth"
require 'typhoeus/adapters/faraday'

require 'job_state.pb'
require 'print_job_state_diff.pb'

module Kinokero

# #########################################################################

  @@config = {
    :default_temp        => "temp"   # placeholder for expansion
  }

  mattr_reader :config

# #########################################################################
end  # module Kinokero
