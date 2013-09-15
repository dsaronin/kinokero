# #########################################################################
 
  require 'faraday'
  require "kinokero/auth_key"
 
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

    #  dependency <some gem>
# ------------------------------------------------------------------------------
# initialize by creating the XSRF token to be used
# ------------------------------------------------------------------------------
    def initialize(app )
      super(app)
      @xsrf = gen_xsrf_token( `uname -n` )
    end

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
  def call(env)

       # make sure request will get set up with token if get,post
    if is_get_or_post?(env)
      env[:body][:xsrf] = @xsrf 
    #  env[:request_headers]['X-Kinokero-XSRF'] = @xsrf 
    end

    @app.call(env).on_complete do |env|

      # validate the XSRF token returned if get, post
      # && successful transaction
      # if env[:response][:success] &&
      if is_get_or_post?(env) &&
         (
           !env[:response].respond_to?( :xsrf ) ||
           env[:response].xsrf != @xsrf
         )

        env[:response].success = false if env[:response].respond_to?( :success )
        env[:response].message = "XSRF token validation failed." if env[:response].respond_to?( :message )
        
          # TODO: remove exception after testing completed
        raise ArgumentError, "XSRF doesn't match"

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
  def gen_xsrf_token( user_secret )
    AuthKey.make_auth_key( user_secret )
  end


# #########################################################################
  end  # class Xsrf

# #########################################################################
end   # module FaradayMiddleware
