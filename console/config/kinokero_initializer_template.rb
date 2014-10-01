# OPTIONAL: Use this as a template for changing kinokero configuration
# put it in your config/initializers directory and rename to 
# kinokero.rb
# values shown below are the defaults in kinokero
# if for some reason you wish to respecify these defaults, precede the
# default name with "Kinokero::", such as the example for my_proxy_id
#
Kinokero.setup do |config|

# ---------------------------------------------------------------------
#  class Proxy required
# ---------------------------------------------------------------------

# two verbose settings are needed: one for Proxy instances and the 
# other for any class-level decisions; the one below is class-level
#   config.verbose             =  false  

# unique name for this running of the GCP connector client
#   config.my_proxy_id         =  Kinokero::MY_PROXY_ID

# picks up your registered Google API client id from environment
#   config.proxy_client_id     =  ENV["GCP_PROXY_CLIENT_ID"]

# picks up your registered Google API client secret from environment
#   config.proxy_client_secret =  ENV["GCP_PROXY_CLIENT_SECRET"]

# picks up a unique serial number for this proxy (future expansion)
#   config.proxy_serial_nbr    =  ENV["GCP_PROXY_SERIAL_NBR"]

# ---------------------------------------------------------------------
#  class Cloudprint required
# ---------------------------------------------------------------------

#   config.mimetype_oauth  = MIMETYPE_OAUTH # how to encoade oauth files

#   config.mimetype_ppd  =   MIMETYPE_PPD   # how to encode PPD files

#   config.mimetype_cdd  =   MIMETYPE_CDD   # how to encode CDD files

#   config.polling_secs  =   POLLING_SECS   # secs to sleep before register polling again

#   config.truncate_log  =   TRUNCATE_LOG   # number of characters to truncate response logs 

#   config.followup_host =   FOLLOWUP_HOST  #

#   config.followup_uri  =   FOLLOWUP_URI   #

#   config.gaia_host  =      GAIA_HOST      #

#   config.login_uri  =      LOGIN_URI      #

#   config.login_url  =      LOGIN_URL      #

#   config.gcp_url  =        GCP_URL        #

#   config.gcp_service  =    GCP_SERVICE    #

#   config.ssl_ca_path  =    SSL_CERT_PATH  # SSL certificates path for this machine

#   config.authorization_scope  =        AUTHORIZATION_SCOPE         #

#   config.authorization_redirect_uri  = AUTHORIZATION_REDIRECT_URI  #

#   config.oauth2_token_endpoint  =      OAUTH2_TOKEN_ENDPOINT       #


# ---------------------------------------------------------------------
#  class Jingle required
# ---------------------------------------------------------------------

#   config.xmpp_server  =     XMPP_SERVER     #  

#   config.ns_google_push  =  NS_GOOGLE_PUSH  #  

#   config.gcp_channel  =     GCP_CHANNEL     #  

# ---------------------------------------------------------------------
#  cups testpage file path
# ---------------------------------------------------------------------

#   config.cups_testpage_file = CUPS_TESTPAGE_FILE

# ---------------------------------------------------------------------
#  printer device/cups related
# ---------------------------------------------------------------------

#   config.printer_poll_cycle = PRINTER_POLL_CYCLE



end  # Kinokero setup
