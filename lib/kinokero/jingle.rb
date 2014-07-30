module Kinokero

# #########################################################################

class Jingle

# #########################################################################

  include Jabber

# #########################################################################

  attr_reader :gcp_channel, :gcp_control, :my_cloudprint

# #########################################################################

# -----------------------------------------------------------------------------
# -----  jabber initialization here   -----------------------------------------
# -----------------------------------------------------------------------------
  def initialize( my_cloudprint, gcp_control )
    @my_cloudprint = my_cloudprint  # cloudprint object
    @gcp_control   = gcp_control
    @gcp_channel   = ::Kinokero.gcp_channel
    @client        = nil
    @is_connection = false    # true if connection established
    @in_callback   = false    # semaphore true during callback stanza
    
    Jabber::debug = true
  end

# -----------------------------------------------------------------------------

  def gtalk_start_connection( &block )

    begin

      begin_connection()    # establishes client protocol

      gtalk_start_subscription()   # starts subscription to receive jobs

      gtalk_notification_callback( &block )  # callback response to notifications

      Jabber::debuglog("**************** protocol ended normally ******************")      

    rescue
      Jabber::debuglog("\e[1;31m**************** protocol yielded exception: #{ $! } ******************\e[0m")      
      @is_connection = false
    end  # block for catch exceptions

  end   # end gtalk_start_connection

# -----------------------------------------------------------------------------

  def begin_connection()
    if @client.nil?
      @sender_jid = Jabber::JID.new( @gcp_control[ :gcp_xmpp_jid ] )
      @client = Jabber::Client.new(@sender_jid)
      @client.jid.resource = @gcp_control[ :gcp_printer_name ]
      @conn = @client.connect(::Kinokero.xmpp_server)
    end
 end

# -----------------------------------------------------------------------------

# setup callback for subscription, which then triggers kinokero
# <message from="cloudprint.google.com" to=”{Full JID}”>
#   <push:push channel="cloudprint.google.com" xmlns:push="google:push">
#     <push:recipient to="{Bare JID}"></push:recipient>
#     <push:data>{Base-64 encoded printer id}</push:data>
#   </push:push>
# </message>
  def gtalk_notification_callback( &block )
    @client.add_message_callback do |m|

      @in_callback = true   # shows we're within callback now

      if m.from == @gcp_channel
          # grab the "push:data" snippet from within the "push:push" snippet
          # from within the current stanza m
          # for better understanding this, see issue & comments at:
          # https://github.com/xmpp4r/xmpp4r/issues/29
       encoded_printerid = m.first_element("push:push").first_element_text("push:data")

       if encoded_printerid.nil?    # is it invalid?
         Jabber::debuglog("GCP CALLBACK printer_id nil ERROR ???????????????")      

       else
            # decode it
         printerid = Base64::strict_decode64(encoded_printerid)

         if printerid.nil?     # is that invalid?
           Jabber::debuglog("GCP CALLBACK decoded printer_id nil ERROR #{encoded_printerid} ???????????????")      

         else

           Jabber::debuglog("GCP CALLBACK: printer_id: #{printerid}")      

              # go into appliance and let it know we need the queue for this printer
           yield( printerid )

          end   # decoded printerid nil  if..then..else
        end   # printerid useless if..then..else
      end    # if channel correct

      @in_callback = false   # shows we're not within callback now

    end  # callback block
  end

# -----------------------------------------------------------------------------

  def gtalk_start_subscription()
    unless @client.nil?

         # prep the Google Talk for GCP subscribe stanza
      iq_subscribe = Jabber::Iq.new( :set, @gcp_control[ :gcp_xmpp_jid ])
      sub_el = iq_subscribe.add_element( 'subscribe', 'xmlns' => ::Kinokero.ns_google_push )
      sub_el.add_element( 'item', 'channel' => @gcp_channel, 'from' => @gcp_channel )

      @client.auth( @my_cloudprint.gcp_form_jingle_auth_token )

      @client.send( iq_subscribe )

      @is_connection = true

    end   # if a client exists

  end

# -----------------------------------------------------------------------------

  def gtalk_close_connection()
    unless @client.nil?  || @in_callback
        # cease responding to message callbacks
      @client.delete_message_callback( nil )

         # prep the Google Talk for GCP unsubscribe stanza
      iq_unsubscribe = Jabber::Iq.new( :set, @gcp_control[ :gcp_xmpp_jid ])
      sub_el = iq_unsubscribe.add_element( 'unsubscribe', 'xmlns' => ::Kinokero.ns_google_push )
      sub_el.add_element( 'item', 'channel' => @gcp_channel, 'from' => @gcp_channel )

        # attempt to unsubscribe (currently GCP returns 501: feature-not-implemented error
      @client.send( iq_unsubscribe )

        # now seal off the connection
      @client.close!

      @client = nil   # and let it vanish away

      @is_connection = false

    end   # if a client exists

  end

# -----------------------------------------------------------------------------

# #########################################################################

end # class Jingle

# #########################################################################

end # module
