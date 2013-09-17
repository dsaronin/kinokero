# #########################################################################
# #########################################################################
# #########################################################################
# Package xsrftoken provides methods for generating and validating secure XSRF tokens.

class XsrfToken

  require 'base64'
  require 'openssl'

  # The duration that XSRF tokens are valid.
  TIMEOUT = 24 * (60 * 60)

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
  def generate(key, userID, actionID)
    return generateAtTime(key, userID, actionID, Time.now)
  end

  # ------------------------------------------------------------------------------
  # generateAtTime is like Generate, but returns a token that expires 24 hours from now.
  # ------------------------------------------------------------------------------
  def generateAtTime(key, userID, actionID, now)

    hmac = OpenSSL::HMAC.digest(
      OpenSSL::Digest::Digest.new('sha1'), 
      key, 
      "#{clean(actionID)}:#{clean(actionID)}:#{now.to_unix_nano.to_str}"
    )
    return Base64.urlsafe_encode64( "#{hmac.to_s}:#{now.to_unix_nano.to_str}" )

  end

  # ------------------------------------------------------------------------------
  # Valid returns true if token is a valid, unexpired token returned by Generate.
  # ------------------------------------------------------------------------------
  def valid?(token, key, userID, actionID ) 
    return validAtTime?(token, key, userID, actionID, Time.now )
  end

  # ------------------------------------------------------------------------------
  # validAtTime is like Valid, but it uses now to check if the token is expired.
  # ------------------------------------------------------------------------------
  def validAtTime?(token, key, userID, actionID, now)
    # Decode the token.
    data = Base64.urlsafe_decode64(token)

    # Extract the issue time of the token.
    issue_time_str = data.split(':')[2]
    return nil if issue_time_str.blank?

    issue_time = Time.fm_unix_nano( issue_time_str.to_i )

    # Check that the token is not expired.
    return nil if now - issue_time >= Timeout 

    # Check that the token is not from the future.
    # Allow 1 minute grace period in case the token is being verified on a
    # machine whose clock is behind the machine that issued the token.
    return nil if issue_time > now + 60

    # Check that the token matches the expected value.
    expected = generateAtTime(key, userID, actionID, issueTime)
    return token == expected
  end

  # #########################################################################

end   # class XsrfToken

