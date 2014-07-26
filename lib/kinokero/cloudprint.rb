
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

    require 'thread'

    extend Forwardable

# #########################################################################

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
GCP_JOBSTATES = %w(DRAFT HELD QUEUED IN_PROGRESS STOPPED DONE ABORTED)
GCP_JOBSTATE_DRAFT = 0 # Job is being created and is not ready for processing yet.;
GCP_JOBSTATE_HELD = 1  # Submitted and ready, but should not be processed yet.;
GCP_JOBSTATE_QUEUED = 2 # Ready for processing.;
GCP_JOBSTATE_IN_PROGRESS = 3 # Currently being processed.
GCP_JOBSTATE_STOPPED = 4   # Was in progress, but stopped due to error or user intervention.;
GCP_JOBSTATE_DONE = 5  # Processed successfully.;
GCP_JOBSTATE_ABORTED = 6  # Aborted due to error or by user action (cancelled).;

# GCP User action causes
GCP_USER_ACTIONS = %(CANCELLED PAUSED OTHER)
GCP_USER_ACTION_CANCELLED = 0  # User has cancelled the job 
GCP_USER_ACTION_PAUSED    = 1  # User has paused the job 
GCP_USER_ACTION_OTHER     = 100  # User has performed some other action 

# GCP connection states
GCP_CONNECTION_STATE_READY = 2  # "ONLINE"
GCP_CONNECTION_STATE_NOT_READY = 3   # "OFFLINE"


# #########################################################################
# #########################################################################

    # default options and configurations for cloudprinting
  DEFAULT_OPTIONS = {
    :verbose => true,         # log everything?
    :auto_connect => true,    # automatically connect active devices?
    :log_truncate => false,   # truncate long responses?
    :log_response => true    # log the responses?
  }

# #########################################################################

    # will be used to determine if user options valid
    # if (in future) any default options were to be off-limits,
    # then a specific sets of keys will have to be enumerated below 
  VALID_CLOUDPRINT_OPTIONS = DEFAULT_OPTIONS.keys

# #########################################################################

  @@connection = nil  # class-wide client http Faraday connection

# #########################################################################

  attr_reader :connection, :gcp_control, :jingle

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
    
    @options = validate_cloudprint_options( DEFAULT_OPTIONS.merge(options) )
    @gcp_control = validate_gcp_control( gcp_control ) 

    Cloudprint.client_connection() # set up faraday connection iff first time

      # set up a reason why jingle not started
    gcp_control[:message] = "device inactive at initialization" unless gcp_control[:is_active]

    if gcp_control[:is_active]  &&
      printer_still_active?()  # verify that this printer is still active

      @jingle = Kinokero::Jingle.new( self, gcp_control ) 
    end  # if active printer

  end


# ------------------------------------------------------------------------------

# sets up the client-to-host faraday connection
#
# * *Args*    :
#   - 
# * *Returns* :
#   - Faraday connection object 
# * *Raises* :
#   - 
# * *Note* :
#   - GCP returns responses as content-type: "text/plain", 
#     so we want faraday to parse all responses from JSON to HASH 
#     regardless of content-type
#
  def self.client_connection()

    @@connection ||= Faraday.new( 
          ::Kinokero.gcp_url, 
          :ssl => { :ca_path => ::Kinokero.ssl_ca_path }
    ) do |faraday|
      #   faraday.request  :retry
#       faraday.request  :oauth2, { 
#         :token     => @gcp_control[ :gcp_access_token ]
#       } 

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
  def self.register_anonymous_printer(params,&block)

      # step 1: issue /register to GCP server
    reg_response = gcp_anonymous_register(params).body

    if (status = reg_response[ 'success' ])  # success; continues

      poll_thread = Thread.new do
      # DEPRECATED: pid = fork do
        # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        # step 3: poll GCP asynchronously as a separate process
        # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        poll_response = gcp_anonymous_poll(reg_response).body

        if poll_response[ 'success' ]  # successful polling registration

            # step 4, obtain OAuth2 authorization tokens
          oauth_response = gcp_get_oauth2_tokens( 
            poll_response[ 'authorization_code' ]
          ).body
          
#                  oauth_response['error'].nil?
#                  oauth_response['error'].to_s

              # create the control hash
            gcp_control = {
              printer_id:        params[:printer_id],
              gcp_printer_name:  reg_response['printers'][0]['name'],

              gcp_xmpp_jid:     poll_response['xmpp_jid'],
              gcp_printerid:    reg_response['printers'][0]['id'],
              gcp_owner_email:  poll_response['user_email'],

              gcp_confirmation_url:      poll_response['confirmation_page_url'],

              gcp_access_token:  oauth_response['access_token'],
              gcp_refresh_token: oauth_response['refresh_token'],
              gcp_token_type:    oauth_response['token_type'],

              gcp_token_expiry_time: Time.now + oauth_response['expires_in'].to_i,

              default_ppd:     params[:default_ppd],
              capability_ppd:  params[:capability_ppd],
              cups_alias:      params[:cups_alias],
              item:            params[:item],
              status:          params[:status],
              virgin_access:   true,  # boolean for dealing with jingle access token quirk
              is_active:       true
            }

            # let calling module save the response for us
          yield( gcp_control )  # persistence
    
        end  # if polling succeeded

        # DEPRECATED: exit
        # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

      end  # fork block

        # force abort of everything if exception in thread
      poll_thread.abort_on_exception = true

      # DEPRECATED: Process.detach(pid) # we are not interested in the exit
      # code of this child and it should become independent
      
    end  # if successful response

      # continue on asynchronously with whatever
      # step 2: tell user where to claim printer
    return {
      success:                 status, 
      swalapala_printer_id:    params[:printer_id],
      gcp_printer_name:        reg_response['printers'][0]['name'],
      gcp_printer_id:          reg_response['printers'][0]['id'],
      gcp_invite_page_url:     reg_response['invite_page_url'],
      gcp_easy_reg_url:        reg_response['complete_invite_url'],
      gcp_auto_invite_url:     reg_response['automated_invite_url'],
      gcp_claim_token_url:     reg_response['invite_url'],
      gcp_printer_reg_token:   reg_response['registration_token'],
      gcp_reg_token_duration:  reg_response['token_duration'],
      cups_alias:              params[:cups_alias] 
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
  def self.gcp_anonymous_register(params)

    reg_response =  Cloudprint.client_connection.post ::Kinokero.gcp_service + GCP_REGISTER do |req|
      req.headers['X-CloudPrint-Proxy'] = ::Kinokero.my_proxy_id 
      req.body =  {
        :printer => params[:gcp_printer_name],
        :proxy   => ::Kinokero.my_proxy_id,
        :description => params[:gcp_printer_name],
        :default_display_name => params[:gcp_printer_name],
        :status => params[:status],
        :capabilities => Faraday::UploadIO.new( 
                  params[:capability_ppd], 
                  ::Kinokero.mimetype_ppd 
        ),
        :defaults => Faraday::UploadIO.new( 
                  params[:default_ppd], 
                  ::Kinokero.mimetype_ppd 
        ),
      }

      Kinokero::Log.log_request( 'get anon-reg', req )

    end  # request do

    Kinokero::Log.log_response( 'anon-reg', reg_response )

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
  def self.gcp_anonymous_poll(anon_response)

    poll_url = anon_response['polling_url'] + Kinokero.proxy_client_id
    printer_id = anon_response['printers'][0]['id']

      # countdown timer for polling loop
    0.step( anon_response['token_duration'].to_i, ::Kinokero.polling_secs ) do |i|

      sleep ::Kinokero.polling_secs    # sleep here until next poll

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
    Kinokero::Log.debug( 'anon-poll' ) { "polling timed out" } if @options[:verbose]

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
  def self.gcp_poll_request( poll_url )
        
    poll_response = Cloudprint.client_connection.post( poll_url ) do |req|  # connection poll request
      req.headers['X-CloudPrint-Proxy'] = ::Kinokero.my_proxy_id 
    end  # post poll response request

    Kinokero::Log.log_response( 'anon-poll', poll_response )

    return poll_response

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
  def self.gcp_get_oauth2_tokens( auth_code )

    oauth_response = Cloudprint.client_connection.post( ::Kinokero.oauth2_token_endpoint ) do |req|
      req.body =  {
        :client_id =>  Kinokero.proxy_client_id,
        :client_secret =>  Kinokero.proxy_client_secret, 
        :redirect_uri => ::Kinokero.authorization_redirect_uri,
        :code => auth_code,
        :grant_type => "authorization_code",
        :scope => ::Kinokero.authorization_scope,
      }

      Kinokero::Log.log_request( 'get oauth2 code', req )
      
    end  # request do

    Kinokero::Log.log_response( 'oauth2 code', oauth_response )

    return oauth_response

  end

# #########################################################################
# #########################################################################
#   instance methods
# #########################################################################
# #########################################################################

# ------------------------------------------------------------------------------

  def gtalk_start_connection(&block)

    if @jingle.nil?

      Kinokero::Log.error( "jingle not started yet; #{@gcp_control[:message]}" )

    else

      @jingle.gtalk_start_connection do |printerid|
        yield( printerid )
      end  # closure for doing print stuff

    end

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
        
    file_response = Cloudprint.client_connection.get( file_url ) do |req|  # connection get job file request
      req.headers['X-CloudPrint-Proxy'] = ::Kinokero.my_proxy_id 
      req.headers['Authorization'] = gcp_form_auth_token()

      log_request( 'get job file', req )
     end  # post poll response request

      # check the RESPONSE_HEADER for SUCCESS
    return ( file_response.env.status == HTTP_RESPONSE_OK  ?
                file_response.env.body  :
                nil
           )

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

    oauth_response = Cloudprint.client_connection.post( ::Kinokero.oauth2_token_endpoint ) do |req|
      req.body =  {
        :client_id =>  Kinokero.proxy_client_id,
        :client_secret =>  Kinokero.proxy_client_secret, 
        :refresh_token => @gcp_control[:gcp_refresh_token],
        :grant_type => "refresh_token"
      }

      log_request( 'get refresh token', req )
      
    end  # request do

    if oauth_response.status == HTTP_RESPONSE_OK

      @gcp_control[:gcp_access_token] = oauth_response.body['access_token']
      @gcp_control[:gcp_token_expiry_time] = 
                  Time.now + oauth_response.body['expires_in'].to_i
      @gcp_control[:virgin_access] = false

    else  # failed to refresh token

      Kinokero::Log.error( 'refresh fail' )  { "**********************************" }

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

    fetch_response = Cloudprint.client_connection.post( ::Kinokero.gcp_service + GCP_FETCH ) do |req|
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

  def gcp_delete_printer( )

    # unsubscribe & close jingle connection
    @jingle.gtalk_close_connection()  unless @jingle.nil?

    remove_response = Cloudprint.client_connection.post( ::Kinokero.gcp_service + GCP_DELETE ) do |req|
      req.headers['Authorization'] = gcp_form_auth_token()
      req.body =  {
        :printerid   => @gcp_control[:gcp_printerid]
      }

      log_request( 'remove printer', req )
      
    end  # request do
    log_response( 'remove printer', remove_response )

    if remove_response[ 'success' ]
      @gcp_control[:is_active] = false
      @jingle = nil   # make available to garbage collect
    end

    return remove_response.body

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

    state_diff = PrintJobStateDiff.new(
      state: JobState.new( type: status ),
      pages_printed: nbr_pages
    )

    return generic_job_status( jobid, state_diff )

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

    state_diff = PrintJobStateDiff.new(
      state: JobState.new( 
              type: GCP_JOBSTATE_ABORTED,
              device_action_cause: DeviceActionCause.new( 
                      error_code: "DOWNLOAD_FAILURE"
              )                   
      ),
      pages_printed: nbr_pages
    )

    return generic_job_status( jobid, state_diff )

  end

# ------------------------------------------------------------------------------

  def gcp_ready_state_changed( ready_state, state, reason )

    state_diff = CloudDeviceState.new(
      cloud_connection_state: 
        ( ready_state ? 
         GCP_CONNECTION_STATE_READY : 
         GCP_CONNECTION_STATE_NOT_READY
        ) ,
      printer: PrinterStateSection.new( 
            state: state.to_s.upcase,

      )
    )

    status_response = Cloudprint.client_connection.post( ::Kinokero.gcp_service + GCP_UPDATE ) do |req|
      req.headers['Authorization'] = gcp_form_auth_token()
      req.body =  {
        :semantic_state_diff  => state_diff.to_json
      }

      log_request( 'device update', req )
      
    end  # request do

    log_response( 'device update', status_response )

    return status_response.body


  end

# ------------------------------------------------------------------------------

# checks GCP server to see if printer still active
#
# * *Args*    :
#   - 
# * *Returns* :
#   - true if still active; false if not
# * *Raises* :
#   - 
# * *side effects* :
#   - changes :is_active status; sets :message for reason
#   
  def printer_still_active?()
    list_result = gcp_get_printer_list

    is_active = false  # assume failure

    if list_result["success"]

      if list_result["printers"].empty?

        @gcp_control[:message] = "proxy printer list empty"

        # try to find a matching printer in the list
      elsif list_result["printers"].any? { |p| p["id"] == @gcp_control[:gcp_printerid] }

        is_active = true   # success here!

      else  # failed to find matching printer in list

        @gcp_control[:message] = "matching printer not found in proxy printer list"

      end   # if..then..else check proxy printer list

    else  # failed to get list result

        @gcp_control[:message] = list_result["message"] || "couldn't obtain proxy printer list"

    end  # able/not get list results

    return (@gcp_control[:is_active] = is_active)

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

    list_response = Cloudprint.client_connection.post( ::Kinokero.gcp_service + GCP_LIST ) do |req|
      req.headers['Authorization'] = gcp_form_auth_token()
      req.body =  {
        :proxy   => ::Kinokero.my_proxy_id
      }

      log_request( 'get printer list', req )
      
    end  # request do
    log_response( 'get printer list', list_response )

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

      # jingle quirk seems to be unable to use the initial, long access token
      # which was returned by the oauth2 call (longer length)
      # but it jingle readily handles the refreshed access token (shorter length)
    if @gcp_control[:virgin_access] ||  
       Time.now >= @gcp_control[:gcp_token_expiry_time] 
      gcp_refresh_tokens 
    end

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
    Kinokero::Log.log_request( msg, req, @options[:verbose] )
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
    Kinokero::Log.log_response( 
        msg, 
        response,
        @options[:verbose] && @options[:log_response]  
    )
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
# * *NOTE* :
#   - currently this is untested!
#
  def gcp_get_auth_tokens(email, password)

    auth_response = Cloudprint.client_connection.post( ::Kinokero.login_url ) do |req|
      req.body =  {
        :accountType => 'GOOGLE',
        :Email       => email,
        :Passwd      => password,
        :service     => ::Kinokero.gcp_service,
        :source      => ::Kinokero.my_proxy_id
      }

      log_request( 'get auth tokens', req )
      
    end  # request do

    return auth_response.body
  end

# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------

# #########################################################################

  protected

# #########################################################################

# ------------------------------------------------------------------------------

# converts a status enum to GCP code word
#
# * *Args*    :
#   - +status+ - enum value for status
# * *Returns* :
#   - string of the GCP code
# * *Raises* :
#   - 
#
  def status_to_code(status)
    return GCP_JOBSTATES[ status ]
  end

# ------------------------------------------------------------------------------

# converts an abort status enum to GCP code word
#
# * *Args*    :
#   - +status+ - enum value for abort status
# * *Returns* :
#   - string of the GCP user action code
# * *Raises* :
#   - 
#
  def abort_status_to_code(status)
    status = 2 if status == GCP_USER_ACTION_OTHER
    return  GCP_USER_ACTIONS[ status ]
  end



# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------

# generic job status reporting
#
# * *Args*    :
#   - +jobid+ - job id string
#   - +state_diff+ - proto_buf JobStateDIff object
# * *Returns* :
#   - 
# * *Raises* :
#   - 
#
  def generic_job_status( jobid, state_diff )

    status_response = Cloudprint.client_connection.post( ::Kinokero.gcp_service + GCP_CONTROL ) do |req|
      req.headers['Authorization'] = gcp_form_auth_token()
      req.body =  {
        :jobid   => jobid,
        :semantic_state_diff  => state_diff.to_json
      }

      log_request( 'status control', req )
      
    end  # request do
    log_response( 'status control', status_response )

    return status_response.body

  end

# ------------------------------------------------------------------------------

# validates user's options
#
# * *Args*    :
#   - +options+ - described in constants 
# * *Returns* :
#   - options hash itself
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
    
    return options
    
  end

# ------------------------------------------------------------------------------

# validate the gcp control options and set object attribute
#
# TBD: validate the options
#
# * *Args*    :
#   - +gcp_control+ - options for setting attribute
# * *Returns* :
#   - the gcp_control hash
# * *Raises*  :
#   - 
#
  def validate_gcp_control( gcp_control )
    return gcp_control
  end


# #########################################################################
  end  # class Cloudprint

# #########################################################################
end  # module Kinokero
