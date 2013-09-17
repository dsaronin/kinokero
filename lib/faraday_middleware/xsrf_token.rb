# #########################################################################
# #########################################################################
class Time

  # ------------------------------------------------------------------------------
  # UnixNano returns Unix time, the number of nanoseconds elapsed 
  #          since January 1, 1970 UTC. 
  # ------------------------------------------------------------------------------
  def to_unix_nano
    return self.to_i * 1000
  end

  def self.fm_unix_nano( nano )
    return Time.at( nano / 1000 )
  end

end # class Time

# #########################################################################
# Package xsrftoken provides methods for generating and validating secure XSRF tokens.
# #########################################################################

class XsrfToken

  require 'base64'
  require 'openssl'

  # The duration that XSRF tokens are valid.
  TIMEOUT = 24 * (60 * 60)

  # ------------------------------------------------------------------------------
  # clean sanitizes a string for inclusion in a token by replacing all ":"s.
  # ------------------------------------------------------------------------------
  def self.clean(str) 
    return str.gsub(/:/, "_")
  end

  # ------------------------------------------------------------------------------
  # Generate returns a URL-safe secure XSRF token that expires in 24 hours.
  #
  # key is a secret key for your application.
  # userID is a unique identifier for the user.
  # actionID is the action the user is taking (e.g. POSTing to a particular path).
  # ------------------------------------------------------------------------------
  def self.generate(key, userID, actionID)
    return generateAtTime(key, userID, actionID, Time.now)
  end

  # ------------------------------------------------------------------------------
  # generateAtTime is like Generate, but returns a token that expires 24 hours from now.
  # ------------------------------------------------------------------------------
  def self.generateAtTime(key, userID, actionID, now)

    hmac = OpenSSL::HMAC.digest(
      OpenSSL::Digest::Digest.new('sha1'), 
      key, 
      "#{clean(actionID)}:#{clean(actionID)}:#{now.to_unix_nano.to_s}"
    )
    return Base64.urlsafe_encode64( hmac.to_s ) + ":#{now.to_unix_nano.to_s}"

  end

  # ------------------------------------------------------------------------------
  # Valid returns true if token is a valid, unexpired token returned by Generate.
  # ------------------------------------------------------------------------------
  def self.valid?(token, key, userID, actionID ) 
    return validAtTime?(token, key, userID, actionID, Time.now )
  end

  # ------------------------------------------------------------------------------
  # validAtTime is like Valid, but it uses now to check if the token is expired.
  # returns false if time valid but not a match
  # returns nil if error in token/time formatting
  # ------------------------------------------------------------------------------
  def self.validAtTime?(token, key, userID, actionID, now)
    split_list = token.split(":") 
    # Decode the token.
    data = Base64.urlsafe_decode64(split_list.first)

    # Extract the issue time of the token.
    issue_time_str = split_list.last
    return nil if issue_time_str.nil? || 
       issue_time_str.empty?          ||
       issue_time_str.match(/\s+/)

    nano_time = issue_time_str.to_i
    return nil if nano_time.zero?
    issue_time = Time.fm_unix_nano( nano_time )

    # Check that the token is not expired.
    return nil if now - issue_time >= TIMEOUT 

    # Check that the token is not from the future.
    # Allow 1 minute grace period in case the token is being verified on a
    # machine whose clock is behind the machine that issued the token.
    return nil if issue_time > now + 60

    # Check that the token matches the expected value.
    expected = generateAtTime(key, userID, actionID, issue_time)
    return token == expected
  end

  # #########################################################################

end   # class XsrfToken

