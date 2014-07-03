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
CLIENT_REDIRECT_URI = "urn:ietf:wg:oauth:2.0:oob"
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

# -----------------------------------------------------------------------------

# jingle constants required

XMPP_SERVER     = "talk.google.com" 
NS_GOOGLE_PUSH  = "google:push"
GCP_CHANNEL     = "cloudprint.google.com"

# -----------------------------------------------------------------------------


# MY_PROXY_ID is a unique name for this running of the GCP connector client
# formed with gem name + machine-node name (expected to be  unique)
# TODO: make sure machine nodename is unique
MY_PROXY_ID = "kinokero::"+`uname -n`.chop

# CLIENT_NAME should be some string identifier for the client you are writing.
CLIENT_NAME = MY_PROXY_ID + " cloudprint controller v0.0.1"



# -----------------------------------------------------------------------------


  @@config = {

      # class Proxy required
    my_proxy_id:     MY_PROXY_ID,    # unique name for this running of the GCP connector client
    client_name:     CLIENT_NAME,    # some string identifier for the client you are writing

      # class Cloudprint required
    mimetype_oauth:  MIMETYPE_OAUTH, # how to encoade oauth files
    mimetype_ppd:    MIMETYPE_PPD,   # how to encode PPD files
    polling_secs:    POLLING_SECS,   # secs to sleep before register polling again
    truncate_log:    TRUNCATE_LOG,   # number of characters to truncate response logs 
    followup_host:   FOLLOWUP_HOST,  #
    followup_uri:    FOLLOWUP_URI,   #
    gaia_host:       GAIA_HOST,      #
    login_uri:       LOGIN_URI,      #
    login_url:       LOGIN_URL,      #
    gcp_url:         GCP_URL,        #
    gcp_service:     GCP_SERVICE,    #

    authorization_scope:         AUTHORIZATION_SCOPE,         #
    authorization_redirect_uri:  AUTHORIZATION_REDIRECT_URI,  #
    oauth2_token_endpoint:       OAUTH2_TOKEN_ENDPOINT,       #

      # class Jingle required
    xmpp_server:      XMPP_SERVER,     #  
    ns_google_push:   NS_GOOGLE_PUSH,  #  
    gcp_channel:      GCP_CHANNEL,     #  



  }

# #########################################################################

  class_eval( "def config; @@config; end;" )

# #########################################################################

# these requires for kinokero modules must occur AFTER the above constants defined
require "kinokero/cloudprint"
require "kinokero/version"
require "kinokero/ruby_extensions"
require 'kinokero/sasl_xoauth2'
require "kinokero/jingle"
require "kinokero/proxy"

# #########################################################################
end  # module Kinokero
