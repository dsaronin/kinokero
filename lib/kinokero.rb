require 'json'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/json/encoding'

require 'faraday-cookie_jar'
require 'logger'
require 'forwardable'

require "faraday"
require "faraday_middleware"
require "simple_oauth"
require 'typhoeus/adapters/faraday'

require 'job_state.pb'
require 'print_job_state_diff.pb'

require 'localized_string.pb'

require 'input_tray_state.pb'
require 'output_bin_state.pb'
require 'marker_state.pb'
require 'cover_state.pb'
require 'media_path_state.pb'
require 'vendor_state.pb'

require 'printer_state_section.pb'
require 'scanner_state_section.pb'
require 'cloud_device_state.pb'
require 'device_action_cause.pb'

require 'xmpp4r/client'

module Kinokero

# #########################################################################

    class PrinteridNotFound < NameError; end

# #########################################################################


CRLF = '\r\n'

# mimetype for how to encode CDD files
MIMETYPE_JSON      = 'application/json'
MIMETYPE_PROTOBUF  = 'application/protobuf'
MIMETYPE_GENERAL   = 'application/octet-stream'
MIMETYPE_CDD       =  MIMETYPE_GENERAL

# mimetype for how to encode PPD files
MIMETYPE_PPD     = 'application/vnd.cups.ppd'

# number of secs to sleep before polling again
POLLING_SECS = 30     

# number of characters before truncate response logs
TRUNCATE_LOG = 1000    

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

# SSL certificates path for this machine
# NOTE: move this out before finalizing gem
SSL_CERT_PATH = "/usr/lib/ssl/certs"

# CUPS system default testpage file
CUPS_TESTPAGE_FILE = "/usr/share/cups/data/default-testpage.pdf"

# printer device status polling cycle (float secs to sleep)
PRINTER_POLL_CYCLE = 15    # wait fifteen seconds before recheck status

# -----------------------------------------------------------------------------

# gem master config area; most settings are alterable as needed
# many, however, are fixed by Google Cloud Printer documentation demands
# and should not be changed
# if making any additions, be sure to add name to mattr_accessor list below
#

# class Proxy required
    @@my_proxy_id         =  MY_PROXY_ID    # unique name for this running of the GCP connector client
    @@proxy_client_id     =  ENV["GCP_PROXY_CLIENT_ID"] || 'missing'
    @@proxy_client_secret =  ENV["GCP_PROXY_CLIENT_SECRET"] || 'missing'
    @@proxy_serial_nbr    =  ENV["GCP_PROXY_SERIAL_NBR"] || 'missing'
    @@verbose             =  true  # for any class-level decisions

# class Cloudprint required
    @@mimetype_oauth  = MIMETYPE_OAUTH # how to encoade oauth files
    @@mimetype_ppd  =   MIMETYPE_PPD   # how to encode PPD files
    @@mimetype_cdd  =   MIMETYPE_CDD   # how to encode CDD files
    @@polling_secs  =   POLLING_SECS   # secs to sleep before register polling again
    @@truncate_log  =   TRUNCATE_LOG   # number of characters to truncate response logs 
    @@followup_host  =  FOLLOWUP_HOST  #
    @@followup_uri  =   FOLLOWUP_URI   #
    @@gaia_host  =      GAIA_HOST      #
    @@login_uri  =      LOGIN_URI      #
    @@login_url  =      LOGIN_URL      #
    @@gcp_url  =        GCP_URL        #
    @@gcp_service  =    GCP_SERVICE    #
    @@ssl_ca_path  =    SSL_CERT_PATH  # SSL certificates path for this machine

    @@authorization_scope  =        AUTHORIZATION_SCOPE         #
    @@authorization_redirect_uri  = AUTHORIZATION_REDIRECT_URI  #
    @@oauth2_token_endpoint  =      OAUTH2_TOKEN_ENDPOINT       #

# class Jingle required
    @@xmpp_server  =     XMPP_SERVER     #  
    @@ns_google_push  =  NS_GOOGLE_PUSH  #  
    @@gcp_channel  =     GCP_CHANNEL     #  

# cups testpage file path
    @@cups_testpage_file = CUPS_TESTPAGE_FILE

# printer device/cups related
    @@printer_poll_cycle = PRINTER_POLL_CYCLE

  mattr_accessor :my_proxy_id,:mimetype_oauth, :mimetype_ppd, :mimetype_cdd, :polling_secs,
    :truncate_log, :followup_host, :followup_uri, :gaia_host, :loging_uri,
    :loging_url, :gcp_url, :gcp_service, :ssl_ca_path, 
    :authorization_scope, :authorization_redirect_uri, :oauth2_token_endpoint,
    :xmpp_server, :ns_google_push, :gcp_channel, :verbose, 
    :proxy_client_secret, :proxy_client_id, :proxy_serial_nbr,
    :cups_testpage_file, :printer_poll_cycle


# #########################################################################

# Default way to setup kinokero configuration
#
  def self.setup
    yield self
  end
 
# #########################################################################

# these requires for kinokero modules must occur AFTER the above constants defined
require "kinokero/cloudprint"
require "kinokero/version"
require "kinokero/ruby_extensions"
require 'kinokero/sasl_xoauth2'
require "kinokero/jingle"
require "kinokero/log"
require "kinokero/device"
require "kinokero/printer"
require "kinokero/proxy"

# #########################################################################
end  # module Kinokero
