require "kinokero/version"
require "kinokero/ruby_extensions"

require "faraday"
require "faraday_middleware"
require "simple_oauth"
require 'typhoeus/adapters/faraday'

module Kinokero
# #########################################################################

  class Cloudprint

# #########################################################################
CRLF = '\r\n'

# The following are used for authentication functions.
FOLLOWUP_HOST = 'www.google.com/cloudprint'
FOLLOWUP_URI = 'select%2Fgaiaauth'
GAIA_HOST = 'www.google.com'
LOGIN_URI = '/accounts/ServiceLoginAuth'
LOGIN_URL = 'https://www.google.com/accounts/ClientLogin'

# unique name for this running of the GCP connector client
# formed with gem name + machine-node name (expected to be  unique)
# TODO: make sure machine nodename is unique
MY_PROXY_ID = "kinokero::"+`uname -n`.chop

# CLIENT_NAME should be some string identifier for the client you are writing.
CLIENT_NAME = MY_PROXY_ID + " cloudprint controller v"+ Kinokero::VERSION

# a GCP path is composed of URL + SERVICE + ACTION
# GCP_URL = 'http://0.0.0.0:3000'
GCP_URL = 'https://www.google.com'
GCP_SERVICE = '/cloudprint'

# GCP API actions
GCP_CONTROL  = '/control'
GCP_DELETE   = '/delete'
GCP_FETCH    = '/fetch'
GCP_LIST     = '/list'
GCP_REGISTER = '/register'
GCP_UPDATE   = '/update'

# mimetype for how to encode PPD files
MIMETYPE_PPD     = 'application/vnd.cups.ppd'

# SSL certificates path for this machine
SSL_CERT_PATH = "/usr/lib/ssl/certs"

# #########################################################################
    # default options and configurations for cloudprinting
  DEFAULT_OPTIONS = {
    :url => GCP_URL    ,
    :oauth_token => nil,
    :ssl_ca_path => SSL_CERT_PATH
  }

# #########################################################################
    # will be used to determine if user options valid
    # if (in future) any default options were to be off-limits,
    # then a specific sets of keys will have to be enumerated below 
  VALID_CLOUDPRINT_OPTIONS = DEFAULT_OPTIONS.keys

# #########################################################################

  attr_reader :connection


# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
  def initialize( options )
    @options = DEFAULT_OPTIONS.merge(options)
    validate_cloudprint_options(@options)
    @connection = setup_connection(@options)
  end

# ------------------------------------------------------------------------------
# validate_cloudprint_options -- validates user's options
# raises exception if invalid
# ------------------------------------------------------------------------------
  def validate_cloudprint_options(options)
# init stuff goes here; options validations;
    options.assert_valid_keys(VALID_CLOUDPRINT_OPTIONS)

# future options checking using following pattern
#    unless (options[:any_key].nil?
#      raise ArgumentError,":any_key must exist"
#    end
    
  end

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
  def setup_connection( options )

#     return Faraday.new( options[:url], options[:ssl] ) do |faraday|
#       faraday.adapter  :typhoeus  # make requests with typhoeus
#     end # do

    return Faraday.new( 
          options[:url], 
          :ssl => { :ca_path => options[:ssl_ca_path] }
    ) do |faraday|
      #   faraday.request  :retry
      unless options[:oauth_token].blank?
        faraday.request  :oauth2, { :token => options[:oauth_token] } 
      end
      faraday.request  :multipart             # multipart files
      faraday.response :json             # json en/decoding
      faraday.request  :url_encoded           # form-encode POST params
      faraday.response :logger                # log requests to STDOUT
      faraday.adapter  :typhoeus  # make requests with typhoeus
    end # do faraday setup
    
  end

      # faraday.adapter Faraday.default_adapter 
# ------------------------------------------------------------------------------
# Anonymous registration requires registering without any login credentials, 
# and then taking some of the returning tokens to complete the registration. 
# Here are the steps required:

  # Access registration URL using HTTPS without authentication tokens
  # Get token back from Cloud Print Service
  # Use the token to claim the printer (with authentication tokens)
  # Get the auth token back from the claim printer step
  # Send auth token to polling URL

# args:
  # printer - string name of printer
# ------------------------------------------------------------------------------
  def register_anonymous_printer(printer, capability_filename, default_filename=nil)

    payload = {
      :printer => printer,
      :proxy   => MY_PROXY_ID,
      :capabilities => Faraday::UploadIO.new( capability_filename, MIMETYPE_PPD ),
    }
    response = @connection.post GCP_SERVICE + GCP_REGISTER do |req|
      req.headers['X-CloudPrint-Proxy'] = MY_PROXY_ID 
      req.body =  payload
    end  # request do

  end

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------

# #########################################################################
  end  # class Cloudprint

# #########################################################################
end  # module Kinokero
