require 'faraday-cookie_jar'
require 'logger'
require 'forwardable'

require "faraday"
require "faraday_middleware"
require "simple_oauth"
require 'typhoeus/adapters/faraday'

require 'job_state.pb'
require 'print_job_state_diff.pb'
require 'xmpp4r/client'

module Kinokero

# #########################################################################

CRLF = '\r\n'

# mimetype for how to encode PPD files
MIMETYPE_PPD     = 'application/vnd.cups.ppd'

# number of secs to sleep before polling again
POLLING_SECS = 30     

# number of characters before truncate response logs
TRUNCATE_LOG = 600    

# authentication function constants
FOLLOWUP_HOST = 'www.google.com/cloudprint'
FOLLOWUP_URI = 'select%2Fgaiaauth'
GAIA_HOST = 'www.google.com'
LOGIN_URI = '/accounts/ServiceLoginAuth'
LOGIN_URL = 'https://www.google.com/accounts/ClientLogin'

# GCP documentation constants
AUTHORIZATION_SCOPE = "https://www.googleapis.com/auth/cloudprint"
AUTHORIZATION_REDIRECT_URI = 'oob'
OAUTH2_TOKEN_ENDPOINT = "https://accounts.google.com/o/oauth2/token"
MIMETYPE_OAUTH =  "application/x-pkcs12"

# The GCP URL path is composed of URL + SERVICE + ACTION
# below three are used when testing locally
#   GCP_URL = 'http://0.0.0.0:3000'
#   GCP_SERVICE = '/'
#   GCP_REGISTER = ''
GCP_URL = 'https://www.google.com/'
GCP_SERVICE = 'cloudprint'


  @@config = {
    :default_temp        => "temp"   # placeholder for expansion
  }

  class_eval( "def config; @@config; end;" )

# these requires for kinokero modules must occur AFTER the above constants defined
require "kinokero/cloudprint"
require "kinokero/version"
require "kinokero/ruby_extensions"
require 'kinokero/sasl_xoauth2'
require "kinokero/jingle"

# #########################################################################
end  # module Kinokero
