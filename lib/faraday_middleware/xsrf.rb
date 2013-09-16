# #########################################################################
 
  require 'faraday'
  require "faraday_middleware/auth_key"
  require 'logger'

  require 'forwardable' 

# #########################################################################
class Time
# ------------------------------------------------------------------------------
# UnixNano returns Unix time, the number of nanoseconds elapsed since January 1, 1970 UTC. 
# ------------------------------------------------------------------------------
def to_unix_nano
  return self.to_i * 1000
end

def self.fm_unix_nano( nano )
  return Time.at( nano / 1000 )
end

end # class Time
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

    #  dependency <some gem>
# ------------------------------------------------------------------------------
# initialize by creating the XSRF token to be used
# ------------------------------------------------------------------------------
    def initialize(app )
      super(app)
      @xsrf = gen_xsrf_token( `uname -n` )
      
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
           env[:response].xsrf != @xsrf
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
  def gen_xsrf_token( user_secret )
    AuthKey.make_auth_key( user_secret )
  end

# #########################################################################
  end  # class Xsrf

# #########################################################################
end   # module FaradayMiddleware

# #########################################################################
# #########################################################################
# #########################################################################
# Package xsrftoken provides methods for generating and validating secure XSRF tokens.
module Xsrftoken

  require 'base64'

# The duration that XSRF tokens are valid.
# It is exported so clients may set cookie timeouts that match generated tokens.
Timeout = 24 * (60 * 60)

# ------------------------------------------------------------------------------
# clean sanitizes a string for inclusion in a token by replacing all ":"s.
# ------------------------------------------------------------------------------
def clean(str) 
  return str.gsub(/:/, "_")
end

# ------------------------------------------------------------------------------
# Generate returns a URL-safe secure XSRF token that expires in 24 hours.
#
# key is a secret key for your application.
# userID is a unique identifier for the user.
# actionID is the action the user is taking (e.g. POSTing to a particular path).
# ------------------------------------------------------------------------------
def Generate(key, userID, actionID)
  return generateAtTime(key, userID, actionID, Time.now)
end

# ------------------------------------------------------------------------------
# generateAtTime is like Generate, but returns a token that expires 24 hours from now.
# ------------------------------------------------------------------------------
def generateAtTime(key, userID, actionID, now)
  h = hmac.New(sha1.New, key )
  fprintf(h, "%s:%s:%d", clean(userID), clean(actionID), now.to_unix_nano )
  tok = sprintf("%s:%d", h.Sum(nil), now.to_unix_nano )
  return Base64.urlsafe_encode64( tok )
end
  # base64.URLEncoding.EncodeToString( tok )
  #urlsafe_decode64
  #urlsafe_encode64
# ------------------------------------------------------------------------------
# Valid returns true if token is a valid, unexpired token returned by Generate.
# ------------------------------------------------------------------------------
def Valid(token, key, userID, actionID ) 
  return validAtTime(token, key, userID, actionID, Time.now )
end

# ------------------------------------------------------------------------------
# validAtTime is like Valid, but it uses now to check if the token is expired.
# ------------------------------------------------------------------------------
def validAtTime(token, key, userID, actionID, now)
  # Decode the token.
  data, err = base64.URLEncoding.DecodeString(token)
  return false unless err.nil?

  # Extract the issue time of the token.
  sep = bytes.LastIndex(data, []byte{':'})
  return false if sep < 0 

  nanos, err = strconv.ParseInt(string(data[sep+1:]), 10, 64)
  return false unless err.nil?

  issueTime = time.Unix(0, nanos)

  # Check that the token is not expired.
  return false if now.Sub(issueTime) >= Timeout 

  # Check that the token is not from the future.
  # Allow 1 minute grace period in case the token is being verified on a
  # machine whose clock is behind the machine that issued the token.
  return false if issueTime.After(now.Add(1 * time.Minute)) 

  # Check that the token matches the expected value.
  expected = generateAtTime(key, userID, actionID, issueTime)
  return token == expected
end

# #########################################################################

end   # module xsrf token

# #########################################################################
