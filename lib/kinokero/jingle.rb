module Kinokero

# #########################################################################

class Jingle

# #########################################################################

  include Jabber

# #########################################################################

  attr_reader :gcp_channel, :gcp_appliance, :gcp_control

# #########################################################################

 
# ****************************************************************************

# ****************************************************************************


# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
  def initialize( gcp_appliance, gcp_control )
    @gcp_appliance = gcp_appliance 
    @gcp_control   = gcp_control
    @gcp_channel   = ::Kinokero.gcp_channel
    @is_connection = false    # true if connection established
  end

# ****************************************************************************
# *****  jabber initialization here   *************************************
# ****************************************************************************
  def gtalk_start_connection()

  Jabber::debug = true

  # TODO: proceed unless @is_connection

  begin
    @sender_jid = Jabber::JID.new( @gcp_control[ :gcp_xmpp_jid ] )
    @client = Jabber::Client.new(@sender_jid)
    @client.jid.resource = @gcp_control[ :gcp_printer_name ]
    @conn = @client.connect(::Kinokero.xmpp_server)

       # prep the Google Talk for GCP subscribe stanza
    @iq_subscribe = Jabber::Iq.new( :set, @gcp_control[ :gcp_xmpp_jid ])
    @sub_el = @iq_subscribe.add_element( 'subscribe', 'xmlns' => ::Kinokero.ns_google_push )
    @sub_el.add_element( 'item', 'channel' => @gcp_channel, 'from' => @gcp_channel )

    @client.auth( @gcp_appliance.cloudprint.gcp_form_jingle_auth_token )

    @client.send( @iq_subscribe )

# setup callback for subscription, which then triggers kinokero
# <message from="cloudprint.google.com" to=”{Full JID}”>
#   <push:push channel="cloudprint.google.com" xmlns:push="google:push">
#     <push:recipient to="{Bare JID}"></push:recipient>
#     <push:data>{Base-64 encoded printer id}</push:data>
#   </push:push>
# </message>

    @client.add_message_callback do |m|
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
           @gcp_appliance.do_print_jobs( printerid )

          end   # decoded printerid nil  if..then..else
        end   # printerid useless if..then..else
      end    # if channel correct
    end  # callback block

    Jabber::debuglog("**************** protocol ended normally ******************")      
    @is_connection = true

  rescue
    Jabber::debuglog("**************** protocol yielded exception: #{ $! } ******************")      
    @is_connection = false
  end  # block for catch exceptions

# -----------------------------------------------------------------------------
  end   # end gtalk_start_connection

# #########################################################################

end # class Jingle

# #########################################################################

end # module
