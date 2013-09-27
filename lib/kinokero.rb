require "kinokero/version"
require "kinokero/ruby_extensions"
require 'faraday-cookie_jar'
require 'logger'
require 'forwardable'

require "faraday"
require "faraday_middleware"
require "simple_oauth"
require 'typhoeus/adapters/faraday'

module Kinokero
# #########################################################################

  class Cloudprint

    extend Forwardable

# #########################################################################
CRLF = '\r\n'

# The following are used for authentication functions.
FOLLOWUP_HOST = 'www.google.com/cloudprint'
FOLLOWUP_URI = 'select%2Fgaiaauth'
GAIA_HOST = 'www.google.com'
LOGIN_URI = '/accounts/ServiceLoginAuth'
LOGIN_URL = 'https://www.google.com/accounts/ClientLogin'

  # from GCP documentation
AUTHORIZATION_SCOPE = "https://www.googleapis.com/auth/cloudprint"
AUTHORIZATION_REDIRECT_URI = 'oob'
OAUTH2_TOKEN_ENDPOINT = "https://accounts.google.com/o/oauth2/token"

# unique name for this running of the GCP connector client
# formed with gem name + machine-node name (expected to be  unique)
# TODO: make sure machine nodename is unique
MY_PROXY_ID = "kinokero::"+`uname -n`.chop

# CLIENT_NAME should be some string identifier for the client you are writing.
CLIENT_NAME = MY_PROXY_ID + " cloudprint controller v"+ Kinokero::VERSION

# a GCP path is composed of URL + SERVICE + ACTION
# below three are used when testing locally
# GCP_URL = 'http://0.0.0.0:3000'
# GCP_SERVICE = '/'
# GCP_REGISTER = ''

GCP_URL = 'https://www.google.com/'
GCP_SERVICE = 'cloudprint'

# GCP API actions
GCP_CONTROL  = '/control'
GCP_DELETE   = '/delete'
GCP_FETCH    = '/fetch'
GCP_LIST     = '/list'
GCP_REGISTER = '/register'
GCP_UPDATE   = '/update'

# GCP ERROR CODES
GCP_ERR_XSRF_FAIL   =   9    # "XSRF token validation failed."
GCP_ERR_NOT_REG_YET = 502    # "Token not registered yet." 
GCP_ERR_NO_GET_AUTH = 505    # "Unable to get the authorization code." 
GCP_ERR_EXPIRED     = 506    # "Token not registered yet." 

# mimetype for how to encode PPD files
MIMETYPE_PPD     = 'application/vnd.cups.ppd'

POLLING_SECS = 30     # number of secs to sleep before polling again
TRUNCATE_LOG = 600    # number of characters before truncate response logs

# #########################################################################
    # default options and configurations for cloudprinting
  DEFAULT_OPTIONS = {
    :url => GCP_URL    ,
    :oauth_token => nil,
    :ssl_ca_path => '',
    :verbose => true,  # log all responses 
    :client_id => '',
    :client_secret => ''
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
    @logger = ::Logger.new(STDOUT)  # in case we need error logging
  end

    def_delegators :@logger, :debug, :info, :warn, :error, :fatal

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

    return Faraday.new( 
          options[:url], 
          :ssl => { :ca_path => options[:ssl_ca_path] }
    ) do |faraday|
      #   faraday.request  :retry
      unless options[:oauth_token].blank?
        faraday.request  :oauth2, { :token => options[:oauth_token] } 
      end
      faraday.use      :cookie_jar       # cookiejar handling
      faraday.request  :multipart        # multipart files
      faraday.response :json             # json en/decoding
      faraday.request  :url_encoded      # form-encode POST params
      faraday.response :logger           # log requests to STDOUT
      faraday.adapter  :typhoeus         # make requests with typhoeus
      # faraday.adapter Faraday.default_adapter # useful for debugging
    end # do faraday setup
    
  end

# ------------------------------------------------------------------------------
# Anonymous registration requires registering without any login credentials, 
# and then taking some of the returning tokens to complete the registration. 
# Here are the steps required:

  # Access registration URL using HTTPS without authentication tokens
  # Get token back from Cloud Print Service
  # Use the token to claim the printer (with authentication tokens)
  # Get the auth token back from the claim printer step
  # Send auth token to polling URL


#   and will require some of this information to be displayed to the user
#   as part of a manual step to go and claim the user's printer.
#   
#       print 'Go claim your printer at this url:'
#       print 'http://www.google.com/cloudprint/claimprinter.html'
#       print 'Use token: response['registration_token']
  
# ------------------------------------------------------------------------------
# register_anonymous_printer -- returns success/failure, response hash
# ------------------------------------------------------------------------------
# args:
  # params  - hash with parameters: 
  #           :id, :printer_name, :capability_ppd, :default_ppd
  # block   - asynchronously will get oauth2 info if user submits token
# ------------------------------------------------------------------------------
  def register_anonymous_printer(params,&block)

      # step 1: issue /register to GCP server
    response = gcp_anonymous_register(params).body

    if (status = response[ 'success' ])  # success; continues

      pid = fork {
        # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        # step 3: poll GCP asynchronously as a separate process
        # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        poll_response = gcp_anonymous_poll(response).body

        if poll_response[ 'success' ]  # successful polling registration

            # step 4, obtain OAuth2 authorization tokens
          oauth_response = gcp_get_oauth2_tokens( poll_response ).body

            # let calling module save the response for us
          yield( params[:id], oauth_response )  # save the oauth info
        end

        exit
        # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      }

      Process.detach(pid) # we are not interested in the exit
      # code of this child and it should become independent
      
    end  # if successful response

      # continue on asynchronously with whatever
      # step 2: tell user where to claim printer
    return status, response

  end

# ------------------------------------------------------------------------------
#   anonymous registration calls will return:
#
#   registration_token: a human readable string the user will need to claim printer ownership
#   token_duration: the lifetime of the registration_token, in seconds (the whole registration has to finish within this time frame)
#   invite_url: the url that a user will need to visit to claim ownership of the printer
#   complete_invite_url: same thing of invite_url but already containing the registration_token, so that the user doesn't have to insert it manually
#   invite_page_url: the url of a printable page containing the user's registration_token and url. (The page can be retrieved by the printer in PDF or PWG-raster format based on the HTTP header of the request, as for getting print jobs. At the moment the page size is letter and the resolution for the raster format is 300dpi. In the near future the page will have the page size and resolution based on the printer defaults.)
#   polling_url: the url that the printer will need to poll for the OAuth2 authorization_code
# ------------------------------------------------------------------------------
# gcp_anonymous_register - posts /register for anon printer; returns response hash
# args:
  # params  - hash with parameters: 
  #           :id, :printer_name, :capability_ppd, :default_ppd
# ------------------------------------------------------------------------------
  def gcp_anonymous_register(params)

    response =  @connection.post GCP_SERVICE + GCP_REGISTER do |req|
      req.headers['X-CloudPrint-Proxy'] = MY_PROXY_ID 
      req.body =  {
        :printer => params[:printer_name],
        :proxy   => MY_PROXY_ID,
        :default_display_name => params[:printer_name],
        :capabilities => Faraday::UploadIO.new( 
                  params[:capability_filename], 
                  MIMETYPE_PPD 
        ),
      }
    end  # request do

    debug( 'anon-reg' ) { response.inspect[0,TRUNCATE_LOG] } if @options[:verbose]

    return response

  end

# ------------------------------------------------------------------------------
# From GCP documentation:
#   If the user has successfully claimed the token then the poll_response hash is:
#   success: is true
#   authorization_code: the OAuth2 authorization_code to be used to get OAuth2 
#     refresh_token and access_token. See details at gcp_get_oauth2_tokens
#   xmpp_jid: this is the jabber id or email address that needs to be used with 
#     Google Talk to subscribe for print notifications. 
#     This needs to be retained in the printer memory forever.
#   user_email: the email address of the user that claimed the 
#     registration_token at the previous step
#   confirmation_page_url: the url of a printable page that confirms to the user 
#     that the printer has been registered to him/herself. 
#     The same notes relative to retrieving the invite_page_url above apply here too.
# ------------------------------------------------------------------------------
# gcp_anonymous_poll - polls GCP server to see if user has claimed token
# returns polling response hash
# args:
  # response - gcp response hash
# ------------------------------------------------------------------------------
  def gcp_anonymous_poll(anon_response)

    poll_url = anon_response['polling_url'] + @options[:client_id]
    printer_id = anon_response['printers'][0]['id']

      # countdown timer for polling loop
    0.step( anon_response['token_duration'].to_i, POLLING_SECS ) do |i|

      sleep POLLING_SECS    # sleep here until next poll

        # poll GCP to see if printer claimed yet?
      poll_response = @connection.post( poll_url ) do |req|  # connection poll request
        req.headers['X-CloudPrint-Proxy'] = MY_PROXY_ID 
      end  # post poll response request

      debug( 'anon-poll' ) { poll_response.inspect[0,TRUNCATE_LOG] } if @options[:verbose]

        # user claimed printer success ?
      # if reg_id == printer_id  ?????????
      return poll_response if 
        poll_response.body[ 'success' ] ||
        poll_response.body["errorCode"] != GCP_ERR_NOT_REG_YET

      #else, continue to poll

    end  # sleep/polling loop

      # log failure
    debug( 'anon-poll' ) { "polling timed out" } if @options[:verbose]
    return { 'success' => false, 'message' =>  "polling timed out" }   # return failure

  end

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# From GCP documentation:
#   the printer must use the authorization_code to obtain OAuth2 Auth tokens, 
#   themselves used to authenticate subsequent API calls to Google Cloud Print. 

#   There are two types of tokens involved:

#     The refresh_token should be retained in printer memory forever. 
#       It can then be used to retrieve a temporary access_token.
#     The access_token needs to be refreshed every hour, 
#       and is used as authentication credentials in subsequent API calls.
  #
#   The printer can initially retrieve both tokens together by POSTing 
#   the authorization_code to the OAuth2 token endpoint at 
#   https://accounts.google.com/o/oauth2/token, 
#     
#   along with the following parameters:

#     client_id (the same that you appended to polling_url when fetching
#         the authorization_code)
#     redirect_uri (set it to 'oob')
#     client_secret (obtained along with client_id as part of your 
#         client credentials)
#     grant_type=authorization_code
#     scope=https://www.googleapis.com/auth/cloudprint 
#       (scope identifies the Google service being accessed, in this case GCP)

#   If this request succeeds, a refresh token and short-lived access token 
#   will be returned via JSON. You can then use the access token to make 
#   API calls by attaching the following Authorization HTTP header to each of 
#   your API calls: Authorization: OAuth YOUR_ACCESS_TOKEN. 
#   You can retrieve additional access tokens once the first expires 
#   (after an hour) by using the token endpoint with your refresh token, 
#   client credentials, and the parameter grant_type=refresh_token.
# ------------------------------------------------------------------------------
# gcp_get_oauth2_tokens -- returns succcess/fail, oauth_response hash
# ------------------------------------------------------------------------------
  def gcp_get_oauth2_tokens( poll_response )

    oauth_response = @connection.post( OAUTH2_TOKEN_ENDPOINT ) do |req|
      req.headers['X-CloudPrint-Proxy'] = MY_PROXY_ID 
      req.body =  {
        :printer => params[:printer],
        :proxy   => MY_PROXY_ID,

        :client_id =>  @options[:client_id],
        :redirect_uri => AUTHORIZATION_REDIRECT_URI,
        :client_secret => @options[:client_secret],
        :grant_type => poll_response[ 'authorization_code' ],
        :scope => AUTHORIZATION_SCOPE
      }
    end  # request do

    debug( 'anon-oauth2' ) { oauth_response.inspect[0,TRUNCATE_LOG] } if @options[:verbose]

  end

# ------------------------------------------------------------------------------
# gcp_get_auth_tokens -- simple auth token requester
  # won't work for accounts that require two-step 
# ------------------------------------------------------------------------------
  def gcp_get_auth_tokens(email, password)

    return @connection.post( LOGIN_URL ) do |req|
      req.body =  {
        :accountType => 'GOOGLE',
        :Email       => email,
        :Passwd      => password,
        :service     => GCP_SERVICE,
        :source      => CLIENT_NAME
      }
    end  # request do

  end
# ------------------------------------------------------------------------------
# From GCP documentation:
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------


# #########################################################################
  end  # class Cloudprint

# #########################################################################
end  # module Kinokero
