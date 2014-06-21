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

#
# handles all interactions with Google Cloud Print server
# but not the jingle-XMPP related connections
#
# == Options
#
# * +:url+ - GCP URL (as formed in constants above)
# * +:oauth_token+ - supplied OAUTH from GCP
# * +:ssl_ca_path+ - local SSL certificates path
# * +:verbose+ - true if verbose logging
# * +:log_truncate+ - true if truncate long responses from the log
# * +:log_response+ - true if log responses from GCP
# * +:client_redirect_uri+ - redirect URL for the same
#
  class Cloudprint

    extend Forwardable

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

# MY_PROXY_ID is a unique name for this running of the GCP connector client
# formed with gem name + machine-node name (expected to be  unique)
# TODO: make sure machine nodename is unique
MY_PROXY_ID = "kinokero::"+`uname -n`.chop

# CLIENT_NAME should be some string identifier for the client you are writing.
CLIENT_NAME = MY_PROXY_ID + " cloudprint controller v"+ Kinokero::VERSION

# The GCP URL path is composed of URL + SERVICE + ACTION
# below three are used when testing locally
#   GCP_URL = 'http://0.0.0.0:3000'
#   GCP_SERVICE = '/'
#   GCP_REGISTER = ''
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

# HTTP RESPONSE CODES
HTTP_RESPONSE_OK             = 200
HTTP_RESPONSE_BAD_REQUEST    = 400
HTTP_RESPONSE_UNAUTHORIZED   = 401
HTTP_RESPONSE_FORBIDDEN      = 403
HTTP_RESPONSE_NOT_FOUND      = 404

# GCP Job States
GCP_JOBSTATE_DRAFT = 0 # Job is being created and is not ready for processing yet.;
GCP_JOBSTATE_HELD = 1  # Submitted and ready, but should not be processed yet.;
GCP_JOBSTATE_QUEUED = 2 # Ready for processing.;
GCP_JOBSTATE_IN_PROGRESS = 3 # Currently being processed.
GCP_JOBSTATE_STOPPED = 4   # Was in progress, but stopped due to error or user intervention.;
GCP_JOBSTATE_DONE = 5  # Processed successfully.;
GCP_JOBSTATE_ABORTED = 6  # Aborted due to error or by user action (cancelled).;

# GCP User action causes
GCP_USER_ACTION_CANCELLED = 0  # User has cancelled the job 
GCP_USER_ACTION_PAUSED    = 1  # User has paused the job 
GCP_USER_ACTION_OTHER     = 100  # User has performed some other action 

# #########################################################################
# #########################################################################

    # default options and configurations for cloudprinting
  DEFAULT_OPTIONS = {
    :url => GCP_URL    ,
    :oauth_token => nil,
    :ssl_ca_path => '',
    :verbose => true,         # log everything?
    :log_truncate => false,   # truncate long responses?
    :log_response => true,    # log the responses?
    :client_redirect_uri => AUTHORIZATION_REDIRECT_URI
  }

# #########################################################################

    # will be used to determine if user options valid
    # if (in future) any default options were to be off-limits,
    # then a specific sets of keys will have to be enumerated below 
  VALID_CLOUDPRINT_OPTIONS = DEFAULT_OPTIONS.keys

# #########################################################################

  attr_reader :connection, :gcp_control

  def_delegators :@logger, :debug, :info, :warn, :error, :fatal

# #########################################################################

# instantiate new CloudPrint object
#
# * *Args*    :
#   - +gcp_control+ - nil or hash of persistent GCP attributes for managed printer
#   - +options+     - hash of optional settings (see above)
# * *Returns* :
#   - CloudPrint object
# * *Raises* :
#   - 
#
  def initialize( gcp_control, options )
    @options = DEFAULT_OPTIONS.merge(options)
    validate_cloudprint_options(@options)
    validate_gcp_control( gcp_control )
    @connection = setup_connection(@options)
    @logger = ::Logger.new(STDOUT)  # in case we need error logging
  end

# ------------------------------------------------------------------------------

# sets up the client-to-host faraday connection
#
# * *Args*    :
#   - 
# * *Returns* :
#   - Faraday connection object based on settings
# * *Raises* :
#   - 
# * *Assumes* :
#   - @gcp_control set up (to determine oauth2 needs)
# * *Note* :
#   - GCP returns responses as content-type: "text/plain", 
#     so we want faraday to parse all responses from JSON to HASH 
#     regardless of content-type
#
  def setup_connection( options )

    return Faraday.new( 
          options[:url], 
          :ssl => { :ca_path => options[:ssl_ca_path] }
    ) do |faraday|
      #   faraday.request  :retry
      unless @gcp_control.blank?
        faraday.request  :oauth2, { 
          :token     => @gcp_control[ :gcp_access_token ]
        } 
      end

      faraday.use      :cookie_jar       # cookiejar handling
      faraday.request  :multipart        # multipart files
      faraday.request  :url_encoded      # form-encode POST params
      faraday.response :json, { :content_type => [ /\bjson$/, /\bplain$/, /\btext$/ ]  }
      faraday.response :logger           # log requests to STDOUT
      # faraday.adapter  :typhoeus         # make requests with typhoeus
      faraday.adapter Faraday.default_adapter # useful for debugging
    end # do faraday setup
    
  end

# ------------------------------------------------------------------------------

# handles the anonymous printer registration protocol
#
# * *Args*    :
#   - +params+  - hash with parameters: 
#     - +:id+ - 
#     - +:printer_name+ - 
#     - +:status+ - (of printer: string) 
#     - +:capability_ppd+ -  (filename)
#     - +:default_ppd+ -  (filename)
#   - +block+   - asynchronously will receive oauth2 info if user submits token
# * *Returns* :
#   - success/failure via response hash
#     - +:success+               - true or false
#     - +:swalapala_printer_id+  - any internal record id for the printer
#     - +:gcp_printer_name+      - string of printer name
#     - +:gcp_printer_id+        - gcp printer id for use in requests
#     - +:gcp_invite_page_url+   - gcp invite page url (see docs)
#     - +:gcp_easy_reg_url+      - gcp one-click url (see docs for complete_invite_url)
#     - +:gcp_auto_invite_url+   - gcp automated_invite_url (see docs)
#     - +:gcp_claim_token_url+   - gcp invite url (see docs)
#     - +:gcp_printer_reg_token+ - gcp registration_token for claiming printer
#     - +:gcp_reg_token_duration+ - gcp token_duration in seconds
# * *Raises* :
#   - 
# 
# == Anonymous registration protocol
# 
# Anonymous registration requires registering without any login credentials, 
# and then taking some of the returning tokens to complete the registration. 
# 
# Here are the steps required:
# * Access registration URL using HTTPS without authentication tokens
# * Get token back from Cloud Print Service
# * Use the token to claim the printer (with authentication tokens)
# * Send query to polling URL; 
# * receive an authentication_code, jabber_url
# * Send authentication_code together with our client_id, etc to oauth2
# * receive access_token, refresh_token
# 
# == anonymous registration calls will return:
#
# registration_token: a human readable string the user will need to claim printer ownership
# token_duration: the lifetime of the registration_token, in seconds (the whole registration has to finish within this time frame)
# invite_url: the url that a user will need to visit to claim ownership of the printer
# complete_invite_url: same thing of invite_url but already containing the registration_token, so that the user doesn't have to insert it manually
# invite_page_url: the url of a printable page containing the user's registration_token and url. (The page can be retrieved by the printer in PDF or PWG-raster format based on the HTTP header of the request, as for getting print jobs. At the moment the page size is letter and the resolution for the raster format is 300dpi. In the near future the page will have the page size and resolution based on the printer defaults.)
# polling_url: the url that the printer will need to poll for the OAuth2 authorization_code
#
# ------------------------------------------------------------------------------
# Display to user following information to claim the user's printer.
#   
#   'Go claim your printer at this url:'
#   'http://www.google.com/cloudprint/claimprinter.html'
#   'Use token: response['registration_token']
# ------------------------------------------------------------------------------
# 
  def register_anonymous_printer(params,&block)

      # step 1: issue /register to GCP server
    reg_response = gcp_anonymous_register(params).body

    if (status = reg_response[ 'success' ])  # success; continues

      pid = fork do
        # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        # step 3: poll GCP asynchronously as a separate process
        # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        poll_response = gcp_anonymous_poll(reg_response).body

        if poll_response[ 'success' ]  # successful polling registration

            # step 4, obtain OAuth2 authorization tokens
          oauth_response = gcp_get_oauth2_tokens( 
            poll_response[ 'authorization_code' ]
          ).body
          
            # complete self instantiation by making this the printer
            # which we control
          @gcp_control = {
            printer_id: params[:id],
            success: oauth_response['error'].nil?,
            message: oauth_response['error'].to_s,
            gcp_xmpp_jid: poll_response['xmpp_jid'],
            gcp_printerid: reg_response['printers'][0]['id'],
            gcp_confirmation_url: poll_response['confirmation_page_url'],
            gcp_owner_email: poll_response['user_email'],

            gcp_access_token: oauth_response['access_token'],
            gcp_refresh_token: oauth_response['refresh_token'],
            gcp_token_type: oauth_response['token_type'],
            gcp_token_expiry_time: Time.now + oauth_response['expires_in'].to_i,
          }

            # let calling module save the response for us
          yield( @gcp_control )  # persistence

          # TODO: start listening for work
          gcp_listen_jabber()
          
        end  # if polling succeeded

        exit
        # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

      end  # fork block

      Process.detach(pid) # we are not interested in the exit
      # code of this child and it should become independent
      
    end  # if successful response

      # continue on asynchronously with whatever
      # step 2: tell user where to claim printer
    return {
      success:                 status, 
      swalapala_printer_id:    params[:id],
      gcp_printer_name:        reg_response['printers'][0]['name'],
      gcp_printer_id:          reg_response['printers'][0]['id'],
      gcp_invite_page_url:     reg_response['invite_page_url'],
      gcp_easy_reg_url:        reg_response['complete_invite_url'],
      gcp_auto_invite_url:     reg_response['automated_invite_url'],
      gcp_claim_token_url:     reg_response['invite_url'],
      gcp_printer_reg_token:   reg_response['registration_token'],
      gcp_reg_token_duration:  reg_response['token_duration']
    }

  end

# ------------------------------------------------------------------------------

# gcp_anonymous_register - posts /register for anon printer; returns response hash
# args:
  # params  - hash with parameters: 
  #           :id, :printer_name, :capability_ppd, :default_ppd, :status
#
# * *Args*    :
#   - ++ - 
#   - ++ - 
# * *Returns* :
#   - 
# * *Raises* :
#   - 
#
  def gcp_anonymous_register(params)

    reg_response =  @connection.post GCP_SERVICE + GCP_REGISTER do |req|
      req.headers['X-CloudPrint-Proxy'] = MY_PROXY_ID 
      req.body =  {
        :printer => params[:printer_name],
        :proxy   => MY_PROXY_ID,
        :description => params[:printer_name],
        :default_display_name => params[:printer_name],
        :status => params[:status],
        :capabilities => Faraday::UploadIO.new( 
                  params[:capability_ppd], 
                  MIMETYPE_PPD 
        ),
        :defaults => Faraday::UploadIO.new( 
                  params[:default_ppd], 
                  MIMETYPE_PPD 
        ),
      }

      log_request( 'get anon-reg', req )

    end  # request do

    log_response( 'anon-reg', reg_response )

    return reg_response

  end

  # req.headers['Authorization'] = "GoogleLogin auth=" + AuthAccessToken
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
#
# * *Args*    :
#   - ++ - 
#   - ++ - 
# * *Returns* :
#   - 
# * *Raises* :
#   - 
#
  def gcp_anonymous_poll(anon_response)

    poll_url = anon_response['polling_url'] + @gcp_control[:proxy_client_id]
    printer_id = anon_response['printers'][0]['id']

      # countdown timer for polling loop
    0.step( anon_response['token_duration'].to_i, POLLING_SECS ) do |i|

      sleep POLLING_SECS    # sleep here until next poll

        # poll GCP to see if printer claimed yet?
      poll_response = gcp_poll_request( poll_url )

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

# gcp_poll_request -- returns response hash after trying a polling POST
#
# * *Args*    :
#   - ++ - 
#   - ++ - 
# * *Returns* :
#   - 
# * *Raises* :
#   - 
#
  def gcp_poll_request( poll_url )
        
    poll_response = @connection.post( poll_url ) do |req|  # connection poll request
      req.headers['X-CloudPrint-Proxy'] = MY_PROXY_ID 
    end  # post poll response request

    log_response( 'anon-poll', poll_response )

    return poll_response

  end

# ------------------------------------------------------------------------------

# gcp_get_job_file -- returns the job file to be printed
#
# * *Args*    :
#   - +file_url+ - url to get the file for printing 
# * *Returns* :
#   - nil if failed to get file; else file itself
# * *Raises* :
#   - 
#
  def gcp_get_job_file( file_url )
        
    file_response = @connection.get( file_url ) do |req|  # connection get job file request
      req.headers['X-CloudPrint-Proxy'] = MY_PROXY_ID 
      req.headers['Authorization'] = gcp_form_auth_token()
      # req.body =  { :printer => params[:printer_name] }

      log_request( 'get job file', req )
     end  # post poll response request

    #  log_response( 'job file', file_response )

      # TODO: can we check the RESPONSE_HEADER for SUCCESS???
    return file_response

  end


# ------------------------------------------------------------------------------

# * *Args*    :
#   - +auth_code+ - 
#   - ++ - 
# * *Returns* :
#   - oauth_response hash
# * *Raises* :
#   - 
#
# From GCP documentation:
# the printer must use the authorization_code to obtain OAuth2 Auth tokens, 
# themselves used to authenticate subsequent API calls to Google Cloud Print. 
#
# There are two types of tokens involved:
#
# * The refresh_token should be retained in printer memory forever. 
#   It can then be used to retrieve a temporary access_token.
# * The access_token needs to be refreshed every hour, 
#   and is used as authentication credentials in subsequent API calls.
#
# The printer can initially retrieve both tokens together by POSTing 
# the authorization_code to the OAuth2 token endpoint at 
# https://accounts.google.com/o/oauth2/token, 
#     
# along with the following parameters:
# * client_id (the same that you appended to polling_url when fetching
#   the authorization_code)
# * redirect_uri (set it to 'oob')
# * client_secret (obtained along with client_id as part of your 
# * client credentials)
# * grant_type="authorization_code"
# * scope=https://www.googleapis.com/auth/cloudprint 
#   (scope identifies the Google service being accessed, in this case GCP)
# If this request succeeds, a refresh token and short-lived access token 
# will be returned via JSON. You can then use the access token to make 
# API calls by attaching the following Authorization HTTP header to each of 
# your API calls: Authorization: OAuth YOUR_ACCESS_TOKEN. 
# You can retrieve additional access tokens once the first expires 
# (after an hour) by using the token endpoint with your refresh token, 
# client credentials, and the parameter grant_type=refresh_token.
#
  def gcp_get_oauth2_tokens( auth_code )

    oauth_response = @connection.post( OAUTH2_TOKEN_ENDPOINT ) do |req|
      req.body =  {
        :client_id =>  @gcp_control[:proxy_client_id],
        :client_secret =>  @gcp_control[:proxy_client_secret], 
        :redirect_uri => AUTHORIZATION_REDIRECT_URI,
        :code => auth_code,
        :grant_type => "authorization_code",
        :scope => AUTHORIZATION_SCOPE,
      }

      log_request( 'get oauth2 code', req )
      
    end  # request do

    log_response( 'oauth2 code', oauth_response )

    return oauth_response

  end

# ------------------------------------------------------------------------------

# refresh an expired gcp auth token
#
# * *Args*    :
#   - 
# * *Returns* :
#   - oauth_response hash showing succcess/fail 
# * *Raises* :
#   - 
#
  def gcp_refresh_tokens( )

    oauth_response = @connection.post( OAUTH2_TOKEN_ENDPOINT ) do |req|
      req.body =  {
        :client_id =>  @gcp_control[:proxy_client_id],
        :client_secret =>  @gcp_control[:proxy_client_secret], 
        :refresh_token => @gcp_control[:gcp_refresh_token],
        :grant_type => "refresh_token"
      }

      log_request( 'get refresh token', req )
      
    end  # request do

    if oauth_response.status == HTTP_RESPONSE_OK

      @gcp_control[:gcp_access_token] = oauth_response.body['access_token']
      @gcp_control[:gcp_token_expiry_time] = 
                  Time.now + oauth_response.body['expires_in'].to_i

    else  # failed to refresh token

      error( 'refresh fail' )  { "**********************************" }

    end  # if..then..else success

    log_response( 'refresh token', oauth_response )

    return oauth_response.body

  end

# ------------------------------------------------------------------------------

# gets a list of jobs queued for a printer
#
# * *Args*    :
#   - +printerid+ - gcp printer_id for the printer
# * *Returns* :
#   - fetch hash including queue
# * *Raises* :
#   - 
#
  def gcp_get_printer_fetch( printerid )

    fetch_response = @connection.post( GCP_SERVICE + GCP_FETCH ) do |req|
      req.headers['Authorization'] = gcp_form_auth_token()
      req.body =  {
        :printerid   => printerid
      }

      log_request( 'fetch queue', req )
      
    end  # request do
    log_response( 'fetch queue', fetch_response )

    return fetch_response.body

  end

# ------------------------------------------------------------------------------

# report status for a print job
#
# * *Args*    :
#   - +jobid+ - gcp job_id
#   - +status+ - GCP_JOBSTATUS_  type
#   - +nbr_pages+ - number of pages printed
# * *Returns* :
#   - 
# * *Raises* :
#   - 
#
  def gcp_job_status( jobid, status, nbr_pages )

    status_response = @connection.post( GCP_SERVICE + GCP_CONTROL ) do |req|
      req.headers['Authorization'] = gcp_form_auth_token()
      req.body =  {
        :jobid   => jobid,
        :state   => { type: status },
        :pages_printed => nbr_pages
      }

      log_request( 'status control', req )
      
    end  # request do
    log_response( 'status control', status_response )

    return status_response.body

  end

# ------------------------------------------------------------------------------

# report abort status for a print job
#
# * *Args*    :
#   - +jobid+ - gcp job_id
#   - +status+ - GCP_USER_ACTION status
#   - +nbr_pages+ - number of pages printed
# * *Returns* :
#   - 
# * *Raises* :
#   - 
#
  def gcp_job_status_abort( jobid, status, nbr_pages )

    status_response = @connection.post( GCP_SERVICE + GCP_CONTROL ) do |req|
      req.headers['Authorization'] = gcp_form_auth_token()
      req.body =  {
        :jobid   => jobid,
        :state   => { type: GCP_JOBSTATE_ABORTED, user_action_cause: status },
        :pages_printed => nbr_pages
      }

      log_request( 'status control', req )
      
    end  # request do
    log_response( 'status control', status_response )

    return status_response.body

  end


# ------------------------------------------------------------------------------

# simple auth token requester;
# won't work for accounts that require two-step 
#
# * *Args*    :
#   - +email+ - proxy owner's email 
#   - +password+ - proxy owner's password
# * *Returns* :
#   - gcp response hash
# * *Raises* :
#   - 
#
  def gcp_get_auth_tokens(email, password)

    return @connection.post( LOGIN_URL ) do |req|
      req.body =  {
        :accountType => 'GOOGLE',
        :Email       => email,
        :Passwd      => password,
        :service     => GCP_SERVICE,
        :source      => CLIENT_NAME
      }

      log_request( 'get auth tokens', req )
      
    end  # request do

  end

# ------------------------------------------------------------------------------

# gcp protocol to get the list of registered printers for the proxy
#
# * *Args*    :
#   - 
# * *Returns* :
#   - 
# * *Raises* :
#   - 
#
  def gcp_get_printer_list(  )

    list_response = @connection.post( GCP_SERVICE + GCP_LIST ) do |req|
      req.headers['Authorization'] = gcp_form_auth_token()
      req.body =  {
        :proxy   => MY_PROXY_ID
      }

      log_request( 'get printer list', req )
      
    end  # request do
    log_response( 'refresh token', list_response )

    return list_response.body

  end

# ------------------------------------------------------------------------------

# forms a fresh TOKEN_TYPE + AUTH_TOKEN string
#
# * *Args*    :
#   -
# * *Returns* :
#   - string for current auth type & token
# * *Raises*  :
#   - 
#
  def gcp_form_auth_token()
    return '' if @gcp_control.nil?
    gcp_refresh_tokens if Time.now >= @gcp_control[:gcp_token_expiry_time] 
    return "#{ @gcp_control[:gcp_token_type] } #{ @gcp_control[:gcp_access_token] }"
  end

# ------------------------------------------------------------------------------

# forms a fresh AUTH_TOKEN string
#
# * *Args*    :
#   -
# * *Returns* :
#   - string for current auth token
# * *Raises*  :
#   - 
#
  def gcp_form_jingle_auth_token()
    return '' if @gcp_control.nil?
    gcp_refresh_tokens if Time.now >= @gcp_control[:gcp_token_expiry_time] 
    return @gcp_control[:gcp_access_token]
  end


# ------------------------------------------------------------------------------

#
# log_request -- will log the farady request params if verbose setting
#
# * *Args*    :
#   - +msg+ - string to identify position in protocol sequence
#   - +req+ - gcp request hash
# * *Returns* :
#   - 
# * *Raises* :
#   - 
#
  def log_request( msg, req )
    if @options[:verbose]
      body = ( req.body.nil?  ?  req  :  req.body )
      puts "\n---------- REQUEST ------------ #{body.class.name} --------------"
      debug( msg ) { body.inspect }
      puts "----------" * 4
    end  # if verbose
  end

# ------------------------------------------------------------------------------

# log the GCP response
# 
# * *Args*    :
#   - +msg+ - string to identify position in protocol sequence
#   - +response+ - gcp response hash
# * *Returns* :
#   - 
# * *Raises* :
#   - 
#
  def log_response( msg, response )
    if @options[:verbose] && @options[:log_response]
      body = ( response.body.nil?  ?  response  :  response.body )
      puts "\n---------- RESPONSE ------------ #{body.class.name} --------------"
      debug( msg ) { body.inspect[0, ( @options[:log_truncate] ? TRUNCATE_LOG : 20000 )] } 
      puts "----------" * 4
    end  # if verbose
  end

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------

# #########################################################################

  protected

# #########################################################################

# ------------------------------------------------------------------------------

# validates user's options
#
# * *Args*    :
#   - +options+ - described in constants 
# * *Returns* :
#   - 
# * *Raises* :
#   - ArgumentError if invalid option present 
#
  def validate_cloudprint_options(options)

    # init stuff goes here; options validations;
    options.assert_valid_keys(VALID_CLOUDPRINT_OPTIONS)

    # future options checking using following pattern
    #    unless (options[:any_key].nil?
    #      raise ArgumentError,":any_key must exist"
    #    end
    
  end

# ------------------------------------------------------------------------------

# validate the gcp control options and set object attribute
#
# TBD: validate the options
#
# * *Args*    :
#   - +gcp_control+ - options for setting attribute
# * *Returns* :
#   - the gcp_control attribute
# * *Raises*  :
#   - 
#
  def validate_gcp_control( gcp_control )
    @gcp_control = gcp_control
  end


# #########################################################################
  end  # class Cloudprint

# #########################################################################
end  # module Kinokero
