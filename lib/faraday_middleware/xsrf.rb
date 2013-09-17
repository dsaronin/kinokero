# #########################################################################
 
  require 'faraday'
  require "faraday_middleware/auth_key"
  require "faraday_middleware/xsrf_token"
  require 'logger'

  require 'forwardable' 

# #########################################################################

# #########################################################################
# #########################################################################

# #########################################################################
# #########################################################################
module FaradayMiddleware

  if Faraday.respond_to? :register_middleware
    Faraday.register_middleware :request,
      :xsrf    => lambda { Xsrf }
  end

# #########################################################################
  # Request middleware that supports XSRF protection
  #
  # Adds XSRF token to all requests; checks for same token in responses
  #
# #########################################################################
  class Xsrf < Faraday::Middleware
   
     extend Forwardable

    ACTIONID = '/index'
    SECRET_KEY = '22b0d106033113df5b06d6c042f1a7457b0f93ee85fd7eb53dec1c4f009dc27a'

    #  dependency <some gem>
# ------------------------------------------------------------------------------
# initialize by creating the XSRF token to be used
# ------------------------------------------------------------------------------
    def initialize(app, options = { :secret => SECRET_KEY, :action => ACTIONID } )

      super(app)

      @secret_key = options[:secret]
      @action_id = options[:action]
      @user_id = `uname -n`

      @xsrf = ::XsrfToken.generate( @secret_key, @user_id, @action_id )
      @logger = ::Logger.new(STDOUT)  # in case we need error logging

    end

    def_delegators :@logger, :debug, :info, :warn, :error, :fatal

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
  def call(env)

       # make sure request will get set up with token if get,post
    if is_post?(env)
      env[:body][:xsrf] = @xsrf 
    #  env[:request_headers]['X-Kinokero-XSRF'] = @xsrf 
    end

    @app.call(env).on_complete do |env|

      # validate the XSRF token returned if get, post
      # && successful transaction
      # if env[:response][:success] &&
      if is_post?(env) &&
         (
           !env[:response].respond_to?( :xsrf ) ||
           !::XsrfToken.valid?(env[:response].xsrf, @secret_key, @user_id, @action_id )
         )

        env[:response].success = false if env[:response].respond_to?( :success )
        env[:response].message = "XSRF token validation failed." if env[:response].respond_to?( :message )
        
        error('response') { "XSRF token validation failed"  } # log issue

      end  # if

    end  # on_complete block
      
  end

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
  def is_get_or_post?(env)
    return ( env[:method] == :get || env[:method] == :post )
  end

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
  def is_post?(env)
    return ( env[:method] == :post )
  end

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

# #########################################################################
  end  # class Xsrf

# #########################################################################
end   # module FaradayMiddleware


