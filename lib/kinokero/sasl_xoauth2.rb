# ****************************************************************************
# ***** addtions to XMPP4R to handle Google Talk X-OAUTH2 ********************
# ****************************************************************************
# ****************************************************************************
# ****************************************************************************

module Jabber

# ****************************************************************************
    
MECHANISM_XOAUTH2       = 'X-OAUTH2'
NS_GOOGLE_AUTH_PROTOCOL = "http://www.google.com/talk/protocol/auth"
NS_GOOGLE_AUTH_SERVICE  = "chromiumsync"
    
# ****************************************************************************

 class Client

# -----------------------------------------------------------------------------
# Authenticate with the server
#
# Throws ClientAuthenticationFailure
#
# Authentication mechanisms are used in the following preference:
# * SASL X-OAUTH2
# * SASL DIGEST-MD5
# * SASL PLAIN
# * Non-SASL digest
# password:: [String]
#
# THIS OVERRIDES XMPP4R method of the same
#
# -----------------------------------------------------------------------------
    def auth(password)

      begin
        if @stream_mechanisms.include? MECHANISM_XOAUTH2
          auth_sasl SASL.new(self, MECHANISM_XOAUTH2), password
        elsif @stream_mechanisms.include? 'DIGEST-MD5'
          auth_sasl SASL.new(self, 'DIGEST-MD5'), password
        elsif @stream_mechanisms.include? 'PLAIN'
          auth_sasl SASL.new(self, 'PLAIN'), password
        else
          auth_nonsasl(password)
        end

      rescue
        Jabber::debuglog("#{$!.class}: #{$!}\n#{$!.backtrace.join("\n")}")
        raise ClientAuthenticationFailure.new, $!.to_s
      end

    end

  end  # class Client

# ****************************************************************************
  # Helpers for SASL authentication (RFC2222)
  #
  # You might not need to use them directly, they are
  # invoked by Jabber::Client#auth
# ****************************************************************************

  module SASL

# -----------------------------------------------------------------------------
# Factory function to obtain a SASL helper for the specified mechanism
# -----------------------------------------------------------------------------
    def SASL.new(stream, mechanism)

      case mechanism

        when MECHANISM_XOAUTH2    # added for the override
          Xoauth2.new(stream)

        when 'DIGEST-MD5'
          DigestMD5.new(stream)

        when 'PLAIN'
          Plain.new(stream)

        when 'ANONYMOUS'
          Anonymous.new(stream)

        else
          raise "Unknown SASL mechanism: #{mechanism}"

      end  # case

    end 

# -----------------------------------------------------------------------------
# cookie is an OAuth2 access token which you obtained from the anonymous registration flow. 
# this is passed as the "password" to auth
# -----------------------------------------------------------------------------
  class Xoauth2 < Base

    def auth(password)

      auth_text = "\x00#{@stream.jid.node}\x00#{password}"
      error = nil

    #  ::Twiga.say_warn 'XOAUTH2: ' + auth_text.inspect + "\n"
    #  ::Twiga.say_warn 'ENCODED: ' + Base64::strict_encode64(auth_text).inspect + "\n"

      @stream.send(
        generate_auth(
          MECHANISM_XOAUTH2, 
          Base64::strict_encode64(auth_text)
        )
      ) do |reply|
        unless reply.name == 'success'
          error = reply.first_element(nil).name
        end
        true
      end  # do reply handling

      raise error unless error.nil?

    end

# ****************************************************************************

    private

# ****************************************************************************
# from the Jingle documentation for CloudPrint
#
#   h) Outgoing stanza from Google Cloud Print proxy or printer
# ****************************************************************************
#   <auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" 
#       mechanism="X-OAUTH2" auth:service="chromiumsync" 
#       auth:allow-generated-jid="true" 
#       auth:client-uses-full-bind-result="true" 
#       xmlns:auth="http://www.google.com/talk/protocol/auth">
#           {Base-64 encoded authentication data}
#   </auth>
# ****************************************************************************
    def generate_auth(mechanism, text=nil)

      auth = REXML::Element.new 'auth'
      auth.add_namespace NS_SASL
      auth.attributes['mechanism'] = mechanism
      auth.attributes['auth:service'] = NS_GOOGLE_AUTH_SERVICE
      auth.attributes['auth:allow-generated-jid'] = "true"
      auth.attributes['auth:client-uses-full-bind-result'] = "true"
      auth.attributes['xmlns:auth'] = NS_GOOGLE_AUTH_PROTOCOL
      auth.text = text
      auth
    end

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

# ****************************************************************************

 end # class Xoauth2

# ****************************************************************************

end # module Sasl

# ****************************************************************************
end # module Jabber

